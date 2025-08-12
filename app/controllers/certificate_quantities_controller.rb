require "ostruct"

class CertificateQuantitiesController < ApplicationController
  def index
    @certificate_quantities = CertificateQuantityPolicy::Scope.new(current_user, CertificateQuantity).resolve
    render "index"
  end

  def show
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    render "show"
  end

  def retire
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "active"
      return head :unprocessable_entity
    end

    @certificate_quantity.retire

    render "show"
  end

  def transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    account_id = params[:account_id]
    organization_id = params[:organization_id]

    if account_id && organization_id
      return head :unprocessable_entity
    end

    if account_id
      if @certificate_quantity.status != "active"
        return head :unprocessable_entity
      end

      account = Account.find_by(id: account_id)
      if !account || account.organization != current_user.organization
        return head :unprocessable_entity
      end
    end

    if organization_id
      organization = Organization.find_by(id: organization_id)
      if !organization || organization == current_user.organization
        return head :unprocessable_entity
      end
    end

    if account_id
      account = Account.find(account_id)
      @certificate_quantity.update(account: account)
    elsif organization_id
      organization = Organization.find(organization_id)
      @certificate_quantity.update(status: "intransit", to_organization: organization)
    end

    render "show"
  end

  def cancel_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    @certificate_quantity.update(status: "active", to_organization: nil)

    render "show"
  end

  def accept_transfer
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    unless @certificate_quantity.status == "intransit"
      return head :unprocessable_entity
    end

    @certificate_quantity.update(status: "active", to_organization: nil, account: current_user.organization.default_account)

    render "show"
  end

  def split
    @certificate_quantity = CertificateQuantity.find(params[:id])
    authorize @certificate_quantity

    quantity = params[:quantity].to_i

    ActiveRecord::Base.transaction do
      @certificate_quantity.split(quantity)
      @certificate_quantity.reload
      render "show"
    end
  rescue Pundit::NotAuthorizedError => e
    head :unauthorized
  rescue StandardError => e
    @errors = OpenStruct.new(full_messages: [ e.message ])
    render "errors", status: :unprocessable_entity
  end
end
