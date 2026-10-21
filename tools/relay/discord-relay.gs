// DOPAGAKI bug-report relay (Google Apps Script).
// The launcher POSTs a JSON report here; this script forwards it to a Discord channel.
// The Discord webhook URL lives only in the Script Properties (never in the public repo).
//
// Setup: see docs/不具合報告の設定.md

const MAX_PER_HOUR = 20;

function doPost(e) {
  try {
    const props = PropertiesService.getScriptProperties();
    const webhook = props.getProperty("WEBHOOK_URL");
    const token = props.getProperty("TOKEN") || "dopagaki-report";
    if (!webhook) return out_("not configured");
    if (!e || !e.postData || e.postData.length > 60000) return out_("bad request");

    const body = JSON.parse(e.postData.contents);
    if (body.token !== token) return out_("forbidden");

    // Simple rate limit so a stray loop cannot flood the channel.
    const cache = CacheService.getScriptCache();
    const hourKey = "count_" + Math.floor(Date.now() / 3600000);
    const count = Number(cache.get(hourKey) || 0);
    if (count >= MAX_PER_HOUR) return out_("rate limited");
    cache.put(hourKey, String(count + 1), 3700);

    const version = String(body.version || "?").slice(0, 20);
    const description = String(body.description || "(no description)").slice(0, 1500);
    const header = "**【不具合報告】** 版 `" + version + "` / ランチャー v" + Number(body.launcher || 0) + "\n" + description;
    const report = String(body.report || "");

    UrlFetchApp.fetch(webhook, {
      method: "post",
      payload: {
        content: header.slice(0, 1900),
        file: Utilities.newBlob(report, "text/plain", "report_" + version + ".txt"),
      },
      muteHttpExceptions: true,
    });
    return out_("ok");
  } catch (err) {
    return out_("error");
  }
}

function out_(text) {
  return ContentService.createTextOutput(text);
}
