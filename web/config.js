(function setCodeMateApiBase() {
  var configured = typeof window.CODEMATE_API_BASE === "string" ? window.CODEMATE_API_BASE.trim() : "";
  if (!configured) return;
  localStorage.setItem("codemate_api_base", configured.replace(/\/+$/, ""));
})();
