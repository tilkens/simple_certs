require "ostruct"

class GenerationsController < ApplicationController
  def index
    @generations = GenerationPolicy::Scope.new(current_user, Generation).resolve
    render "index"
  end

  def show
    @generation = Generation.find(params[:id])
    authorize @generation

    render "show"
  end

  def create
    @generation = Generation.new(generation_params)
    authorize @generation

    if @generation.save
      render "show", status: :created
    else
      @errors = @generation.errors
      render "errors", status: :unprocessable_entity
    end
  end

  def generation_params
    params.permit(:start_date, :end_date, :quantity, :generator_id)
  end
end
