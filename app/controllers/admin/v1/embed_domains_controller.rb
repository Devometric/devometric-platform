# frozen_string_literal: true

module Admin
  module V1
    class EmbedDomainsController < BaseController
      before_action :set_embed_domain, only: [:update, :destroy]

      def index
        domains = current_company.embed_domains.order(:domain)
        render json: { domains: domains.map { |d| domain_json(d) } }
      end

      def create
        domain = current_company.embed_domains.create!(domain_params)
        render json: { domain: domain_json(domain) }, status: :created
      end

      def update
        @embed_domain.update!(domain_params)
        render json: { domain: domain_json(@embed_domain) }
      end

      def destroy
        @embed_domain.destroy!
        render json: { success: true }
      end

      private

      def set_embed_domain
        @embed_domain = current_company.embed_domains.find(params[:id])
      end

      def domain_params
        params.require(:domain).permit(:domain, :active)
      end

      def domain_json(domain)
        {
          id: domain.id,
          domain: domain.domain,
          active: domain.active,
          created_at: domain.created_at.iso8601
        }
      end
    end
  end
end
