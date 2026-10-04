class Rooms::RefreshesController < ApplicationController
  include RoomScoped

  before_action :set_last_updated_at, :set_thread

  def show
    @new_messages = timeline.with_creator.page_created_since(@last_updated_at)
    @updated_messages = @room.messages.without(@new_messages).with_creator.page_updated_since(@last_updated_at)
  end

  private
    def set_thread
      @thread = @room.messages.find(params[:thread_id]) if params[:thread_id].present?
    end

    def timeline
      @thread ? @thread.replies : @room.messages.top_level
    end

    def set_last_updated_at
      @last_updated_at = Time.at(0, params[:since].to_i, :millisecond)
    end
end
