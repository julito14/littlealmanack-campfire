module Users::SidebarHelper
  def sidebar_turbo_frame_tag(src: nil, &)
    turbo_frame_tag :user_sidebar, src: src, target: "_top", data: {
      turbo_permanent: true,
      controller: "rooms-list read-rooms turbo-frame",
      rooms_list_unread_class: "unread",
      action: "presence:present@window->rooms-list#read read-rooms:read->rooms-list#read turbo:frame-load->rooms-list#loaded refresh-room:visible@window->turbo-frame#reload".html_safe # otherwise -> is escaped
    }, &
  end

  # One of the circles at the top of the menu. Gets a dot when its list has something unread.
  def sidebar_list_tab(name, label, icon)
    tag.button type: "button", class: "direct sidebar-lists__tab borderless fill-transparent unpad",
        aria: { expanded: "false", controls: "#{name}_list" },
        data: { name: name, sidebar_lists_target: "tab", action: "sidebar-lists#select", sidebar_lists_name_param: name } do
      tag.span(image_tag(icon, size: 22, class: "colorize--black", aria: { hidden: "true" }), class: "avatar avatar--icon") +
      tag.span(tag.span(label, class: "txt-nowrap"), class: "direct__author flex align-center max-width min-width border-radius txt-small")
    end
  end
end
