// Refresh release details; the static download link also works without JavaScript.
fetch("https://api.github.com/repos/diegocodehub/autotype/releases/latest")
  .then((response) => {
    if (!response.ok) throw new Error("No public release yet");
    return response.json();
  })
  .then((release) => {
    const asset = release.assets?.find((item) => item.name === "AutoType.dmg");
    if (!asset || release.draft || release.prerelease) return;
    const url = new URL(asset.browser_download_url);
    if (
      url.origin !== "https://github.com" ||
      !url.pathname.startsWith("/diegocodehub/autotype/releases/download/")
    )
      return;
    const button = document.getElementById("download");
    button.href = url.href;
    button.textContent = "Download for Mac ↓";
    document.getElementById("release-status").textContent =
      `${release.tag_name} · Free download · Signed and notarized`;
  })
  .catch(() => {
    /* The static download link remains available if the API is unavailable. */
  });
