/**
 * DOPAGAKI cloud ingest (Google Apps Script) - runs on Google's servers, the PC does not need to be on.
 *
 * Every minute it looks at the shared Drive folder. When a new project ZIP is there it
 *   1. shares the ZIP by link (so GitHub can download it),
 *   2. starts the GitHub workflow "ingest" (merge -> build -> release),
 *   3. waits for the result, un-shares the ZIP and moves it to
 *      取り込み済み / 要確認 / 失敗 / 古いZIP, and writes a line to 配信状況.txt.
 *
 * Setup: see docs/クラウド自動配信の設定.md
 */

// ---- settings ----------------------------------------------------------------------------
var ROOT_FOLDER_ID = '1oAZwPnr_vquU7M55wKtLBHwI3ofXQX7S'; // shared Drive folder "DOPA"
var REPO = 'kobusan5000-cmyk/dopagaki';
var WORKFLOW = 'ingest.yml';
var BRANCH = 'main';
var MIN_AGE_SECONDS = 30;    // ignore a ZIP that was changed less than this long ago (still uploading)
var GIVE_UP_MINUTES = 45;    // a run that is not finished after this long is treated as failed
// -------------------------------------------------------------------------------------------

var INBOX_NAME = 'ここにZIPを入れる';
var STATUS_NAME = '配信状況.txt';

function tick() {
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(5000)) return;
  try {
    var props = PropertiesService.getScriptProperties();
    var pending = props.getProperty('pending');
    if (pending) {
      checkPending_(props, JSON.parse(pending));
    } else {
      startNext_(props);
    }
  } finally {
    lock.releaseLock();
  }
}

/** Run once from the editor: authorises the script and creates the 1-minute trigger. */
function setup() {
  ScriptApp.getProjectTriggers().forEach(function (t) { ScriptApp.deleteTrigger(t); });
  ScriptApp.newTrigger('tick').timeBased().everyMinutes(1).create();
  if (!PropertiesService.getScriptProperties().getProperty('GITHUB_TOKEN')) {
    throw new Error('GITHUB_TOKEN is not set (Project Settings > Script properties).');
  }
  var root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  Logger.log('OK. Folder: ' + root.getName() + ' / trigger created.');
}

// ---- step 1: pick a ZIP and start GitHub ----------------------------------------------------
function startNext_(props) {
  if (Date.now() < Number(props.getProperty('retryAfter') || 0)) return;
  var root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  var zips = listZips_(root);
  if (zips.length === 0) return;
  zips.sort(function (a, b) { return b.getLastUpdated() - a.getLastUpdated(); });
  var newest = zips[0];
  if ((Date.now() - newest.getLastUpdated().getTime()) < MIN_AGE_SECONDS * 1000 || newest.getSize() < 1000) return;

  // Older ZIPs must never be published later (they would roll the game back).
  for (var i = 1; i < zips.length; i++) moveTo_(root, zips[i], '古いZIP');

  var dispatchedAt = Date.now();
  try {
    newest.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
    var res = github_('post', '/actions/workflows/' + WORKFLOW + '/dispatches', {
      ref: BRANCH,
      inputs: { file_id: newest.getId(), file_name: newest.getName() }
    });
    if (res.code !== 204) throw new Error('GitHub answered ' + res.code + ': ' + res.body);
  } catch (e) {
    // Keep the ZIP where it is and try again later; say so once.
    status_(root, '配信を開始できませんでした(' + newest.getName() + '): ' + e.message, true);
    try { newest.setSharing(DriveApp.Access.PRIVATE, DriveApp.Permission.NONE); } catch (x) {}
    props.setProperty('retryAfter', String(Date.now() + 10 * 60 * 1000));
    return;
  }
  props.deleteProperty('retryAfter');
  props.setProperty('pending', JSON.stringify({
    fileId: newest.getId(), name: newest.getName(), dispatchedAt: dispatchedAt, runId: null
  }));
}

function listZips_(root) {
  var out = [];
  [root, firstFolder_(root, INBOX_NAME)].forEach(function (folder) {
    if (!folder) return;
    var it = folder.getFiles();
    while (it.hasNext()) {
      var f = it.next();
      if (/\.zip$/i.test(f.getName())) out.push(f);
    }
  });
  return out;
}

// ---- step 2: wait for the GitHub run and file the ZIP ------------------------------------------
function checkPending_(props, p) {
  var root = DriveApp.getFolderById(ROOT_FOLDER_ID);
  var ageMin = (Date.now() - p.dispatchedAt) / 60000;

  if (!p.runId) {
    var list = github_('get', '/actions/workflows/' + WORKFLOW + '/runs?event=workflow_dispatch&per_page=10');
    if (list.code === 200) {
      var runs = JSON.parse(list.body).workflow_runs || [];
      // oldest run that was created after we asked for it
      runs.sort(function (a, b) { return new Date(a.created_at) - new Date(b.created_at); });
      for (var i = 0; i < runs.length; i++) {
        if (new Date(runs[i].created_at).getTime() >= p.dispatchedAt - 15000) { p.runId = runs[i].id; break; }
      }
    }
    if (!p.runId) {
      if (ageMin > 5) finish_(props, root, p, 'failed', 'GitHub は処理を開始しませんでした');
      return;
    }
    props.setProperty('pending', JSON.stringify(p));
  }

  var run = github_('get', '/actions/runs/' + p.runId);
  if (run.code !== 200) { if (ageMin > GIVE_UP_MINUTES) finish_(props, root, p, 'failed', '結果を確認できませんでした'); return; }
  var info = JSON.parse(run.body);
  if (info.status !== 'completed') {
    if (ageMin > GIVE_UP_MINUTES) finish_(props, root, p, 'failed', '時間内に終わりませんでした');
    return;
  }

  // Which "RESULT: ..." step ran?
  var result = 'failed', tag = '';
  var jobs = github_('get', '/actions/runs/' + p.runId + '/jobs');
  if (jobs.code === 200) {
    (JSON.parse(jobs.body).jobs || []).forEach(function (job) {
      (job.steps || []).forEach(function (s) {
        var m = /^RESULT: (\w+)/.exec(s.name);
        if (m && s.conclusion === 'success') result = m[1];
      });
    });
  }
  if (result === 'published') {
    var rel = github_('get', '/releases/latest');
    if (rel.code === 200) tag = JSON.parse(rel.body).tag_name || '';
  }
  finish_(props, root, p, result, tag);
}

function finish_(props, root, p, result, detail) {
  var file = null;
  try { file = DriveApp.getFileById(p.fileId); } catch (e) {}
  if (file) {
    try { file.setSharing(DriveApp.Access.PRIVATE, DriveApp.Permission.NONE); } catch (e) {}
    var folder = { published: '取り込み済み', nochange: '取り込み済み', held: '要確認', failed: '失敗' }[result] || '失敗';
    moveTo_(root, file, folder);
  }
  var text = {
    published: '公開しました: ' + detail + ' (' + p.name + ') -> テスターに配信',
    nochange: '変更なし: ' + p.name,
    held: '要確認: ' + p.name + ' は削除されるファイルがあるため、公開を保留しました(管理者が確認します)',
    failed: '失敗: ' + p.name + ' ' + (detail ? '(' + detail + ')' : '(ゲームにエラーがある可能性があります。管理者に連絡してください)')
  }[result];
  status_(root, text, false);
  props.deleteProperty('pending');
}

// ---- helpers ----------------------------------------------------------------------------------
function github_(method, path, payload) {
  var token = PropertiesService.getScriptProperties().getProperty('GITHUB_TOKEN');
  var opts = {
    method: method,
    muteHttpExceptions: true,
    headers: {
      Authorization: 'Bearer ' + token,
      Accept: 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28'
    }
  };
  if (payload) { opts.contentType = 'application/json'; opts.payload = JSON.stringify(payload); }
  var r = UrlFetchApp.fetch('https://api.github.com/repos/' + REPO + path, opts);
  return { code: r.getResponseCode(), body: r.getContentText() };
}

function firstFolder_(parent, name) {
  var it = parent.getFoldersByName(name);
  return it.hasNext() ? it.next() : null;
}

function moveTo_(root, file, folderName) {
  var dest = firstFolder_(root, folderName) || root.createFolder(folderName);
  file.moveTo(dest);
}

/** Newest line first, 30 lines max. `onlyIfNew` skips the write when the top line already says the same. */
function status_(root, text, onlyIfNew) {
  var tz = Session.getScriptTimeZone();
  var line = Utilities.formatDate(new Date(), tz, 'yyyy-MM-dd HH:mm') + '  ' + text;
  var it = root.getFilesByName(STATUS_NAME);
  if (!it.hasNext()) { root.createFile(STATUS_NAME, line + '\n', 'text/plain'); return; }
  var f = it.next();
  var old = f.getBlob().getDataAsString('UTF-8').replace(/^﻿/, '').split(/\r?\n/).filter(function (l) { return l; });
  if (onlyIfNew && old.length && old[0].substring(18) === text) return;
  f.setContent([line].concat(old.slice(0, 29)).join('\n') + '\n');
}
