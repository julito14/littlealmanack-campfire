module SupportPagesHelper
  # What members read: the administrator's text, or the starting text until there is one.
  def support_text
    if Current.account.support_text.present?
      Current.account.support_text
    else
      tag.div render("support_pages/default"), class: "lexxy-content"
    end
  end

  # What the editor starts from, so editing begins with the text members already see.
  def support_text_for_editing
    Current.account.support_text.presence || render("support_pages/default")
  end
end
