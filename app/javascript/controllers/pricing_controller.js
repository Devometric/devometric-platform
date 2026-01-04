import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["symbol", "amount", "period"]

  // Prices in different currencies (roughly equivalent)
  static prices = {
    USD: { symbol: "$", amount: "199", period: "/month" },
    EUR: { symbol: "€", amount: "189", period: "/month" },
    GBP: { symbol: "£", amount: "159", period: "/month" },
    CAD: { symbol: "CA$", amount: "269", period: "/month" },
    AUD: { symbol: "A$", amount: "299", period: "/month" },
    SEK: { symbol: "", amount: "2,099", period: " kr/month" },
    NOK: { symbol: "", amount: "2,149", period: " kr/month" },
    DKK: { symbol: "", amount: "1,399", period: " kr/month" },
    CHF: { symbol: "CHF ", amount: "179", period: "/month" }
  }

  // Country to currency mapping
  static countryCurrency = {
    // USD
    US: "USD", PR: "USD", GU: "USD", VI: "USD", AS: "USD",
    // EUR
    DE: "EUR", FR: "EUR", IT: "EUR", ES: "EUR", NL: "EUR", BE: "EUR", AT: "EUR",
    PT: "EUR", IE: "EUR", FI: "EUR", GR: "EUR", SK: "EUR", SI: "EUR", LT: "EUR",
    LV: "EUR", EE: "EUR", CY: "EUR", MT: "EUR", LU: "EUR",
    // GBP
    GB: "GBP", UK: "GBP",
    // CAD
    CA: "CAD",
    // AUD
    AU: "AUD", NZ: "AUD",
    // Nordic
    SE: "SEK", NO: "NOK", DK: "DKK",
    // CHF
    CH: "CHF", LI: "CHF"
  }

  connect() {
    this.detectLocation()
  }

  async detectLocation() {
    try {
      // Use ipapi.co for geolocation (free tier: 1000 requests/day)
      const response = await fetch("https://ipapi.co/json/", {
        signal: AbortSignal.timeout(3000)
      })

      if (!response.ok) throw new Error("Geolocation failed")

      const data = await response.json()
      const countryCode = data.country_code

      this.updatePricing(countryCode)
    } catch (error) {
      // Default to USD on error
      console.log("Using default currency (USD)")
      this.updatePricing("US")
    }
  }

  updatePricing(countryCode) {
    const currency = this.constructor.countryCurrency[countryCode] || "USD"
    const pricing = this.constructor.prices[currency] || this.constructor.prices.USD

    if (this.hasSymbolTarget) {
      this.symbolTarget.textContent = pricing.symbol
    }
    if (this.hasAmountTarget) {
      this.amountTarget.textContent = pricing.amount
    }
    if (this.hasPeriodTarget) {
      this.periodTarget.textContent = pricing.period
    }
  }
}
