module SeoHelper
  LOCALE_TO_OG = {
    en: "en_US",
    fi: "fi_FI",
    sv: "sv_SE",
    es: "es_ES",
    de: "de_DE"
  }.freeze

  def locale_to_og_locale(locale)
    LOCALE_TO_OG[locale.to_sym] || "en_US"
  end

  def hreflang_url(locale)
    base_url = request.base_url
    # Remove any existing locale prefix from path
    clean_path = request.path.sub(%r{^/(en|fi|sv|es|de)(?=/|$)}, "")
    clean_path = "/" if clean_path.empty?

    if locale.to_sym == I18n.default_locale
      "#{base_url}#{clean_path}"
    else
      "#{base_url}/#{locale}#{clean_path}"
    end
  end

  def alternate_locale_urls
    I18n.available_locales.map do |locale|
      { locale: locale, url: hreflang_url(locale) }
    end
  end
end
