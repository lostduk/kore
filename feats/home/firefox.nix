{ outputs, ... }:

let
  c = outputs.palette.colors;

  startup = {
    "browser.aboutConfig.showWarning" = false;
    "browser.shell.checkDefaultBrowser" = false;
    "browser.shell.skipDefaultBrowserCheckOnFirstRun" = true;
    "browser.startup.page" = 0;
    "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
    "browser.newtabpage.enabled" = false;
    "browser.newtabpage.activity-stream.showSponsored" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
    "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
    "browser.newtabpage.activity-stream.default.sites" = "";
    "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSearch" = false;
    "browser.newtabpage.activity-stream.showWeather" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;
    "browser.topsites.contile.enabled" = false;
    "browser.topsites.useRemoteSetting" = false;
    "browser.startup.homepage_override.mstone" = "ignore";
    "startup.homepage_welcome_url" = "";
    "startup.homepage_welcome_url.additional" = "";
    "startup.homepage_override_url" = "";
    "startup.homepage_override_nimbus_disable_wnp" = true;
    "browser.aboutwelcome.enabled" = false;
    "browser.disableResetPrompt" = true;
  };

  locale = {
    "geo.enabled" = false;
    "geo.provider.network.url" = "";
    "geo.provider.use_geoclue" = false;
    "geo.provider.geoclue.always_high_accuracy" = false;
    "browser.region.network.url" = "";
    "browser.region.update.enabled" = false;
    "intl.multilingual.enabled" = true;
    "intl.multilingual.downloadEnabled" = false;
    "intl.multilingual.aboutWelcome.languageMismatchEnabled" = false;
    "intl.locale.requested" = "";
    "app.update.langpack.enabled" = false;
    "extensions.getAddons.langpacks.url" = "";
  };

  telemetry = {
    "datareporting.policy.dataSubmissionEnabled" = false;
    "datareporting.policy.dataSubmissionPolicyAcceptedVersion" = 999;
    "datareporting.policy.dataSubmissionPolicyBypassNotification" = true;
    "datareporting.policy.dataSubmissionPolicyNotifiedTime" = "32503679999000";
    "datareporting.healthreport.uploadEnabled" = false;
    "termsofuse.acceptedDate" = "32503679999000";
    "termsofuse.acceptedVersion" = 999;
    "termsofuse.bypassNotification" = true;
    "toolkit.telemetry.unified" = false;
    "toolkit.telemetry.enabled" = false;
    "toolkit.telemetry.server" = "data:,";
    "toolkit.telemetry.archive.enabled" = false;
    "toolkit.telemetry.newProfilePing.enabled" = false;
    "toolkit.telemetry.shutdownPingSender.enabled" = false;
    "toolkit.telemetry.updatePing.enabled" = false;
    "toolkit.telemetry.bhrPing.enabled" = false;
    "toolkit.telemetry.firstShutdownPing.enabled" = false;
    "toolkit.coverage.opt-out" = true;
    "toolkit.coverage.endpoint.base" = "";
    "browser.newtabpage.activity-stream.telemetry" = false;
    "browser.contentblocking.database.enabled" = false;
    "browser.contentblocking.cfr-milestone.enabled" = false;
    "toolkit.shopping.ohttpConfigURL" = "";
    "toolkit.shopping.ohttpRelayURL" = "";
    "media.webvtt.debug.logging" = false;
    "media.webvtt.testing.events" = false;
    "app.shield.optoutstudies.enabled" = false;
    "app.normandy.enabled" = false;
    "app.normandy.api_url" = "";
    "breakpad.reportURL" = "";
    "browser.tabs.crashReporting.sendReport" = false;
    "browser.crashReports.unsubmittedCheck.autoSubmit2" = false;
  };

  quieter = {
    "extensions.getAddons.showPane" = false;
    "extensions.htmlaboutaddons.recommendations.enabled" = false;
    "extensions.getAddons.discovery.api_url" = "";
    "extensions.recommendations.themeRecommendationUrl" = "";
    "browser.discovery.enabled" = false;
    "browser.newtabpage.activity-stream.asrouter.providers.cfr" = "null";
    "browser.newtabpage.activity-stream.asrouter.providers.message-groups" = "null";
    "browser.newtabpage.activity-stream.asrouter.providers.messaging-experiments" = "null";
    "browser.newtabpage.activity-stream.asrouter.providers.onboarding" = "null";
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.addons" = false;
    "browser.newtabpage.activity-stream.asrouter.userprefs.cfr.features" = false;
    "captivedetect.canonicalURL" = "";
    "network.captive-portal-service.enabled" = false;
    "network.connectivity-service.enabled" = false;
    "network.manage-offline-status" = false;
    "browser.urlbar.trustPanel.breachAlerts" = false;
    "browser.urlbar.trustPanel.breachAlerts.featureGate" = false;
    "browser.contentblocking.report.cookie.url" = "";
    "browser.contentblocking.report.cryptominer.url" = "";
    "browser.contentblocking.report.fingerprinter.url" = "";
    "browser.contentblocking.report.social.url" = "";
    "browser.contentblocking.report.tracker.url" = "";
    "browser.contentblocking.report.endpoint_url" = "";
    "browser.contentblocking.report.lockwise.enabled" = false;
    "browser.contentblocking.report.lockwise.how_it_works.url" = "";
    "browser.contentblocking.report.manage_devices.url" = "";
    "browser.contentblocking.report.monitor.enabled" = false;
    "browser.contentblocking.report.monitor.how_it_works.url" = "";
    "browser.contentblocking.report.monitor.sign_in_url" = "";
    "browser.contentblocking.report.monitor.url" = "";
    "browser.contentblocking.report.monitor.home_page_url" = "";
    "browser.contentblocking.report.monitor.preferences_url" = "";
    "browser.contentblocking.report.hide_vpn_banner" = true;
    "browser.contentblocking.report.show_mobile_app" = false;
    "browser.vpn_promo.enabled" = false;
    "browser.preferences.moreFromMozilla" = false;
    "app.feedback.baseURL" = "";
    "app.support.baseURL" = "";
    "app.releaseNotesURL" = "";
    "app.update.url.details" = "";
    "app.update.url.manual" = "";
    "app.update.staging.enabled" = false;
    "app.update.auto" = false;
    "gecko.handlerService.defaultHandlersVersion" = 999;
    "browser.search.update" = false;
    "permissions.manager.defaultsUrl" = "";
    "browser.uitour.enabled" = false;
    "browser.uitour.url" = "";
    "identity.fxaccounts.enabled" = false;
    "signon.firefoxRelay.feature" = "disabled";
    "browser.firefox-view.virtual-list.enabled" = false;
    "reader.parse-on-load.enabled" = false;
    "browser.gnome-search-provider.enabled" = false;
  };

  ai = {
    "browser.ml.enable" = false;
    "browser.ml.chat.enabled" = false;
    "browser.ml.chat.shortcuts" = false;
    "browser.ml.chat.sidebar" = false;
    "browser.ml.chat.menu" = false;
    "browser.ml.linkPreview.supportedLocales" = "null";
    "browser.preferences.aiControls" = false;
    "browser.ai.control.default" = "blocked";
  };

  safebrowsing = {
    "browser.safebrowsing.malware.enabled" = false;
    "browser.safebrowsing.phishing.enabled" = false;
    "browser.safebrowsing.allowOverride" = false;
    "browser.safebrowsing.blockedURIs.enabled" = false;
    "browser.safebrowsing.downloads.enabled" = false;
    "browser.safebrowsing.downloads.remote.enabled" = false;
    "browser.safebrowsing.downloads.remote.url" = "";
    "browser.safebrowsing.downloads.remote.block_potentially_unwanted" = false;
    "browser.safebrowsing.downloads.remote.block_uncommon" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous" = false;
    "browser.safebrowsing.downloads.remote.block_dangerous_host" = false;
    "browser.safebrowsing.provider.google.updateURL" = "";
    "browser.safebrowsing.provider.google.gethashURL" = "";
    "browser.safebrowsing.provider.google.reportURL" = "";
    "browser.safebrowsing.provider.google.reportMalwareMistakeURL" = "";
    "browser.safebrowsing.provider.google.reportPhishMistakeURL" = "";
    "browser.safebrowsing.provider.google.advisoryURL" = "";
    "browser.safebrowsing.provider.google4.updateURL" = "";
    "browser.safebrowsing.provider.google4.gethashURL" = "";
    "browser.safebrowsing.provider.google4.reportURL" = "";
    "browser.safebrowsing.provider.google4.reportMalwareMistakeURL" = "";
    "browser.safebrowsing.provider.google4.reportPhishMistakeURL" = "";
    "browser.safebrowsing.provider.google4.dataSharing.enabled" = false;
    "browser.safebrowsing.provider.google4.dataSharingURL" = "";
    "browser.safebrowsing.provider.google4.advisoryURL" = "";
    "browser.safebrowsing.provider.mozilla.gethashURL" = "";
    "browser.safebrowsing.provider.mozilla.updateURL" = "";
    "browser.safebrowsing.reportPhishURL" = "";
  };

  network = {
    "network.prefetch-next" = false;
    "network.dns.disablePrefetch" = true;
    "network.dns.disablePrefetchFromHTTPS" = true;
    "network.http.speculative-parallel-limit" = 0;
    "browser.places.speculativeConnect.enabled" = false;
    "browser.urlbar.speculativeConnect.enabled" = false;
    "network.proxy.socks_remote_dns" = true;
    "network.file.disable_unc_paths" = true;
    "network.dns.preferIPv6" = true;
    "network.trr.mode" = 3;
    "network.trr.uri" = "https://dns.mullvad.net/dns-query";
    "network.trr.custom_uri" = "https://dns.mullvad.net/dns-query";
    "network.IDN_show_punycode" = true;
    "network.auth.subresource-http-auth-allow" = 1;
    "network.http.referer.XOriginTrimmingPolicy" = 2;
    "network.http.referer.spoofSource" = true;
    "network.http.referer.defaultPolicy.trackers" = 1;
    "network.http.referer.defaultPolicy.trackers.pbmode" = 1;
    "beacon.enabled" = false;
  };

  urlbar = {
    "browser.urlbar.quicksuggest.enabled" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;
    "browser.search.suggest.enabled" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.suggest.engines" = false;
    "browser.urlbar.suggest.history" = false;
    "browser.urlbar.suggest.bookmark" = false;
    "browser.urlbar.suggest.openpage" = false;
    "browser.urlbar.suggest.topsites" = false;
    "browser.urlbar.suggest.weather" = false;
    "browser.urlbar.trending.featureGate" = false;
    "browser.urlbar.addons.featureGate" = false;
    "browser.urlbar.amp.featureGate" = false;
    "browser.urlbar.importantDates.featureGate" = false;
    "browser.urlbar.market.featureGate" = false;
    "browser.urlbar.mdn.featureGate" = false;
    "browser.urlbar.weather.featureGate" = false;
    "browser.urlbar.wikipedia.featureGate" = false;
    "browser.urlbar.yelp.featureGate" = false;
    "browser.urlbar.yelpRealtime.featureGate" = false;
    "browser.urlbar.clipboard.featureGate" = false;
    "browser.urlbar.recentsearches.featureGate" = false;
    "browser.urlbar.autoFill" = false;
    "browser.urlbar.trimHttps" = false;
    "browser.urlbar.trimURLs" = false;
    "browser.urlbar.filter.javascript" = true;
    "browser.urlbar.showSearchTerms.enabled" = false;
    "browser.search.separatePrivateDefault" = true;
    "browser.search.separatePrivateDefault.ui.enabled" = true;
    "browser.formfill.enable" = false;
    "layout.css.visited_links_enabled" = false;
  };

  passwords = {
    "signon.rememberSignons" = false;
    "signon.autofillForms" = false;
    "signon.formlessCapture.enabled" = false;
    "signon.generation.enabled" = false;
    "signon.management.page.breach-alerts.enabled" = false;
    "signon.management.page.breachAlertUrl" = "";
    "security.webauthn.always_allow_direct_attestation" = false;
    "extensions.formautofill.addresses.enabled" = false;
    "extensions.formautofill.creditCards.enabled" = false;
  };

  disk = {
    "browser.cache.disk.enable" = false;
    "browser.privatebrowsing.forceMediaMemoryCache" = true;
    "media.memory_cache_max_size" = 65536;
    "browser.sessionstore.privacy_level" = 2;
    "browser.sessionstore.interval" = 30000;
    "browser.chrome.site_icons" = false;
    "places.history.enabled" = false;
    "browser.download.start_downloads_in_tmp_dir" = true;
    "browser.helperApps.deleteTempFileOnExit" = true;
    "browser.download.manager.addToRecentDocs" = false;
  };

  tls = {
    "security.ssl.require_safe_negotiation" = true;
    "security.ssl.treat_unsafe_negotiation_as_broken" = true;
    "security.tls.enable_0rtt_data" = false;
    "security.tls.version.enable-deprecated" = false;
    "security.tls.enable_kyber" = true;
    "network.http.http3.enable_0rtt" = false;
    "network.http.http3.enable_kyber" = true;
    "security.OCSP.enabled" = 0;
    "security.OCSP.require" = false;
    "security.ssl.enable_ocsp_stapling" = false;
    "security.cert_pinning.enforcement_level" = 2;
    "security.enterprise_roots.enabled" = false;
    "security.certerrors.mitm.auto_enable_enterprise_roots" = false;
    "security.certerrors.mitm.priming.enabled" = false;
    "security.certerrors.mitm.priming.endpoint" = "";
    "security.pki.mitm_canary_issuer" = "";
    "security.pki.mitm_canary_issuer.enabled" = false;
    "security.pki.mitm_detected" = false;
    "security.qwacs.enabled" = false;
    "security.insecure_field_warning.ignore_local_ip_address" = false;
    "dom.security.https_only_mode" = true;
    "dom.security.https_only_mode_send_http_background_request" = false;
    "browser.xul.error_pages.expert_bad_cert" = true;
    "security.csp.reporting.enabled" = false;
    "security.dialog_enable_delay" = 1000;
  };

  media = {
    "media.peerconnection.enabled" = false;
    "media.peerconnection.ice.proxy_only_if_behind_proxy" = true;
    "media.navigator.enabled" = false;
    "media.gmp-gmpopenh264.enabled" = false;
    "media.gmp-provider.enabled" = true;
    "media.gmp-widevinecdm.enabled" = true;
    "media.eme.enabled" = true;
    "browser.eme.ui.enabled" = true;
    "media.webspeech.synth.enabled" = false;
    "dom.webaudio.enabled" = false;
    "webgl.disabled" = true;
    "webgl.enable-webgl2" = false;
    "dom.webgpu.enabled" = false;
    "pdfjs.enableWebGPU" = false;
  };

  dom = {
    "dom.disable_window_move_resize" = true;
    "dom.webserial.enabled" = false;
    "dom.webserial.gated" = true;
    "dom.push.enabled" = false;
    "dom.push.connection.enabled" = false;
    "dom.push.serverURL" = "";
    "dom.push.userAgentID" = "";
    "dom.gamepad.enabled" = false;
    "dom.netinfo.enabled" = false;
    "dom.vibrator.enabled" = false;
    "dom.w3c_touch_events.enabled" = 0;
    "dom.textMetrics.actualBoundingBox.enabled" = false;
    "dom.textMetrics.baselines.enabled" = false;
    "dom.textMetrics.emHeight.enabled" = false;
    "dom.textMetrics.fontBoundingBox.enabled" = false;
    "device.sensors.enabled" = false;
    "browser.link.open_newwindow" = 3;
    "browser.link.open_newwindow.restriction" = 0;
    "pdfjs.disabled" = false;
    "pdfjs.enableScripting" = false;
    "mathml.disabled" = true;
    "gfx.font_rendering.graphite.enabled" = false;
    "gfx.font_rendering.opentype_svg.enabled" = false;
  };

  javascript = {
    "javascript.options.ion" = false;
    "javascript.options.baselinejit" = false;
    "javascript.options.wasm" = false;
    "javascript.options.wasm_baselinejit" = false;
    "javascript.options.jit_trustedprincipals" = true;
    "javascript.options.spectre.disable_for_isolated_content" = false;
  };

  sandbox = {
    "fission.autostart" = true;
    "gfx.webrender.all" = true;
    "security.sandbox.gpu.level" = 1;
    "browser.tabs.remote.separatePrivilegedMozillaWebContentProcess" = false;
    "browser.tabs.remote.separatedMozillaDomains" = "";
    "dom.ipc.processCount.privilegedmozilla" = 0;
    "devtools.debugger.remote-enabled" = false;
    "browser.contentanalysis.enabled" = false;
    "browser.contentanalysis.default_result" = 0;
    "privacy.antitracking.isolateContentScriptResources" = true;
  };

  extensions = {
    "extensions.enabledScopes" = 5;
    "extensions.postDownloadThirdPartyPrompt" = false;
    "extensions.webcompat.enable_shims" = true;
    "extensions.webcompat-reporter.enabled" = false;
    "extensions.getAddons.cache.enabled" = false;
    "privacy.resistFingerprinting.block_mozAddonManager" = true;
  };

  tracking = {
    "browser.contentblocking.category" = "strict";
    "network.cookie.cookieBehavior.optInPartitioning" = true;
    "network.cookie.cookieBehavior.optInPartitioning.pbmode" = true;
    "network.cookie.sameSite.laxByDefault" = true;
    "network.cookie.sameSite.noneRequiresSecure" = true;
    "network.cookie.sameSite.schemeful" = true;
    "privacy.trackingprotection.allow_list.baseline.enabled" = true;
    "privacy.trackingprotection.allow_list.convenience.enabled" = true;
    "privacy.trackingprotection.allow_list.hasMigratedCategoryPrefs" = true;
    "privacy.firstparty.isolate" = false;
    "privacy.donottrackheader.enabled" = false;
    "privacy.globalprivacycontrol.enabled" = true;
    "privacy.globalprivacycontrol.pbmode.enabled" = true;
    "privacy.userContext.enabled" = true;
    "privacy.userContext.ui.enabled" = true;
    "privacy.query_stripping.strip_list" = "__hsfp __hssc __hstc __s _bhlid _branch_match_id _branch_referrer _gl _hsenc _openstat at_recipient_id at_recipient_list bbeml bsft_clkid bsft_uid dclid et_rid fb_action_ids fb_comment_id gbraid fbclid gclid guce_referrer guce_referrer_sig hsCtaTracking irclickid mc_eid ml_subscriber ml_subscriber_hash msclkid mtm_cid oft_c oft_ck oft_d oft_id oft_ids oft_k oft_lk oft_sk oly_anon_id oly_enc_id pk_cid rb_clickid s_cid sc_customer sc_eh sc_uid sfmc_activityid sfmc_id sms_click sms_source sms_uph srsltid ss_email_id syclid ttclid twclid unicorn_click_id vero_conv vero_id vgo_ee wbraid wickedid yclid ymclid ysclid";
  };

  sanitize = {
    "privacy.sanitize.sanitizeOnShutdown" = true;
    "privacy.sanitize.timeSpan" = 0;
    "privacy.clearOnShutdown_v2.cache" = true;
    "privacy.clearOnShutdown_v2.cookiesAndStorage" = true;
    "privacy.clearOnShutdown_v2.formdata" = true;
    "privacy.clearOnShutdown_v2.historyFormDataAndDownloads" = true;
    "privacy.clearOnShutdown_v2.browsingHistoryAndDownloads" = true;
    "privacy.clearOnShutdown_v2.downloads" = true;
    "privacy.clearSiteData.cache" = true;
    "privacy.clearSiteData.cookiesAndStorage" = false;
    "privacy.clearSiteData.formdata" = true;
    "privacy.clearSiteData.historyFormDataAndDownloads" = true;
    "privacy.clearSiteData.browsingHistoryAndDownloads" = true;
    "privacy.clearHistory.cache" = true;
    "privacy.clearHistory.cookiesAndStorage" = false;
    "privacy.clearHistory.formdata" = true;
    "privacy.clearHistory.historyFormDataAndDownloads" = true;
    "privacy.clearHistory.browsingHistoryAndDownloads" = true;
  };

  fingerprinting = {
    "privacy.resistFingerprinting" = false;
    "privacy.resistFingerprinting.pbmode" = false;
    "privacy.fingerprintingProtection" = true;
    "privacy.fingerprintingProtection.pbmode" = true;
    "privacy.fingerprintingProtection.overrides" = "+AllTargets,-CSSPrefersColorScheme";
    "privacy.fingerprintingProtection.remoteOverrides.enabled" = false;
    "privacy.baselineFingerprintingProtection" = true;
    "privacy.baselineFingerprintingProtection.overrides" = "";
    "privacy.baselineFingerprintingProtection.granularOverrides" = "";
    "privacy.resistFingerprinting.letterboxing" = true;
    "privacy.spoof_english" = 2;
    "ui.use_standins_for_native_colors" = true;
    "widget.non-native-theme.use-theme-accent" = false;
  };

  permissions = {
    "permissions.default.geo" = 2;
    "permissions.default.camera" = 2;
    "permissions.default.microphone" = 2;
    "permissions.default.desktop-notification" = 2;
    "permissions.default.xr" = 2;
  };

  behaviour = {
    "browser.download.useDownloadDir" = false;
    "browser.download.alwaysOpenPanel" = false;
    "browser.download.always_ask_before_handling_new_types" = true;
    "browser.tabs.searchclipboardfor.middleclick" = false;
    "browser.tabs.warnOnClose" = false;
    "browser.tabs.warnOnCloseOtherTabs" = false;
    "browser.tabs.warnOnOpen" = false;
    "browser.warnOnQuit" = false;
    "browser.warnOnQuitShortcut" = false;
    "full-screen-api.warning.delay" = 0;
    "full-screen-api.warning.timeout" = 0;
    "accessibility.typeaheadfind" = false;
    "clipboard.autocopy" = false;
    "layout.spellcheckDefault" = 0;
    "browser.shareqrcode.embed_logo" = false;
  };

  sidebar = {
    "sidebar.visibility" = "hide-sidebar";
    "sidebar.verticalTabs" = false;
    "sidebar.main.tools" = "";
  };

  theme = {
    "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
    "extensions.activeThemeID" = "firefox-compact-dark@mozilla.org";
    "layout.css.prefers-color-scheme.content-override" = 0;
  };
in {
  programs.firefox = {
    enable = true;

    policies = {
      DisableTelemetry = true;
      DisableFirefoxStudies = true;
      DisableFirefoxAccounts = true;
      DisablePocket = true;
      DontCheckDefaultBrowser = true;
      PasswordManagerEnabled = false;
      OfferToSaveLogins = false;
      OverrideFirstRunPage = "";
      OverridePostUpdatePage = "";

      ExtensionSettings = {
        "*".installation_mode = "blocked";

        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
          private_browsing = true;
        };
      };
    };

    profiles.default = {
      id = 0;
      isDefault = true;

      search = {
        force = true;
        default = "ddg";
        privateDefault = "ddg";
      };

      settings = startup // locale // telemetry // quieter // ai
        // safebrowsing // network // urlbar // passwords // disk // tls
        // media // dom // javascript // sandbox // extensions // tracking
        // sanitize // fingerprinting // permissions // behaviour // sidebar // theme;

      userChrome = ''
        :root {
          --lwt-accent-color: ${c.bg} !important;
          --lwt-accent-color-inactive: ${c.bg} !important;
          --lwt-text-color: ${c.fg} !important;

          --toolbox-background-image: none !important;
          --toolbox-background-color: ${c.bg} !important;
          --toolbox-background-color-inactive: ${c.bg} !important;
          --toolbox-text-color: ${c.fg} !important;
          --toolbox-text-color-inactive: ${c.dim} !important;

          --tab-background-color-selected: ${c.bgAlt} !important;
          --tab-text-color-selected: ${c.fg} !important;
          --tab-border-color-selected-leading: ${c.green} !important;
          --tab-border-color-selected-trailing: ${c.green} !important;
          --lwt-tab-line-color: ${c.green} !important;
          --tab-loading-fill: ${c.green} !important;
          --lwt-background-tab-separator-color: ${c.surface} !important;

          --toolbar-background-color: ${c.bgAlt} !important;
          --toolbar-text-color: ${c.fg} !important;
          --toolbarbutton-icon-fill: ${c.fg} !important;
          --toolbarbutton-icon-fill-attention: ${c.green} !important;
          --toolbarbutton-background-color-hover: color-mix(in srgb, ${c.green} 12%, transparent) !important;
          --toolbarbutton-background-color-active: color-mix(in srgb, ${c.green} 22%, transparent) !important;
          --toolbarseparator-color: ${c.surface} !important;
          --tabs-navbar-separator-color: transparent !important;
          --chrome-content-separator-color: ${c.surface} !important;

          --toolbar-field-background-color: ${c.bg} !important;
          --toolbar-field-background-color-focus: ${c.bg} !important;
          --toolbar-field-text-color: ${c.fg} !important;
          --toolbar-field-text-color-focus: ${c.fg} !important;
          --toolbar-field-border-color: ${c.surface} !important;
          --toolbar-field-border-color-focus: ${c.green} !important;
          --lwt-toolbar-field-highlight: ${c.surface} !important;
          --lwt-toolbar-field-highlight-text: ${c.fg} !important;

          --panel-background-color: ${c.bg} !important;
          --panel-text-color: ${c.fg} !important;
          --panel-border-color: ${c.surface} !important;
          --urlbarview-background-color-selected: ${c.surface} !important;
          --urlbarview-text-color-selected: ${c.fg} !important;

          --sidebar-background-color: ${c.bg} !important;
          --sidebar-text-color: ${c.fg} !important;
          --sidebar-border-color: ${c.surface} !important;
          --tabpanel-background-color: ${c.bg} !important;

          --focus-outline-color: ${c.green} !important;
        }

        #sidebar-button,
        #sidebar-container,
        #sidebar-launcher-splitter,
        #sidebar-box,
        #sidebar-splitter {
          display: none !important;
        }
      '';
    };
  };
}
