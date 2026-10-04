class MessagesController < ApplicationController
  include ActiveStorage::SetCurrent, RoomScoped

  before_action :set_room, except: :create
  before_action :set_message, only: %i[ show edit update destroy ]
  before_action :ensure_can_administer, only: %i[ edit update destroy ]

  layout false, only: :index

  def index
    @messages = find_paged_messages

    if @messages.any?
      fresh_when @messages
    else
      head :no_content
    end
  end

  def create
    set_room
    @message = @room.messages.create_with_attachment!(message_params.merge(parent_message: thread_parent))

    @message.broadcast_create
    deliver_webhooks_to_bots
  rescue ActiveRecord::RecordNotFound
    render action: :room_not_found
  end

  def show
  end

  def edit
  end

  def update
    @message.update!(message_params)

    @message.broadcast_replace_to @room, :messages, target: [ @message, :presentation ], partial: "messages/presentation", attributes: { maintain_scroll: true }

    respond_to do |format|
      format.html { redirect_to room_message_url(@room, @message) }
      format.json { render :show }
    end
  end

  def destroy
    @message.destroy
    @message.broadcast_remove
  end

  private
    def set_message
      @message = @room.messages.find(params[:id])
    end

    def ensure_can_administer
      head :forbidden unless Current.user.can_administer?(@message)
    end


    def find_paged_messages
      case
      when params[:before].present?
        timeline.with_creator.page_before(@room.messages.find(params[:before]))
      when params[:after].present?
        timeline.with_creator.page_after(@room.messages.find(params[:after]))
      else
        timeline.with_creator.last_page
      end
    end

    # The room pages through its own messages; an open thread pages through its replies.
    def timeline
      if params[:thread_id].present?
        @room.messages.find(params[:thread_id]).replies
      else
        @room.messages.top_level
      end
    end

    def thread_parent
      @room.messages.find(params[:thread_id]) if params[:thread_id].present?
    end


    def message_params
      params.require(:message).permit(:body, :attachment, :client_message_id)
    end


    def deliver_webhooks_to_bots
      bots_eligible_for_webhook.excluding(@message.creator).each { |bot| bot.deliver_webhook_later(@message) }
    end

    def bots_eligible_for_webhook
      @room.direct? ? @room.users.active_bots : @message.mentionees.active_bots
    end
end
