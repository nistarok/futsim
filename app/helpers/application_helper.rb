module ApplicationHelper
  def current_user
    @current_user
  end

  def user_signed_in?
    current_user.present?
  end

  # Helpers para cores de clubes
  def club_primary_color(club)
    club.primary_color
  end

  def club_secondary_color(club)
    club.secondary_color
  end

  def club_gradient(club)
    club.gradient
  end

  def club_contrast_text(color)
    # Converte cor hex para RGB e calcula luminância
    color = color.gsub('#', '')
    r = color[0..1].to_i(16)
    g = color[2..3].to_i(16)
    b = color[4..5].to_i(16)

    # Fórmula de luminância relativa
    luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255

    # Retorna branco ou preto baseado na luminância
    luminance > 0.5 ? '#000000' : '#FFFFFF'
  end

  def club_button_style(club, type = 'primary')
    case type
    when 'primary'
      "background-color: #{club_primary_color(club)}; color: #{club_contrast_text(club_primary_color(club))}; border: none; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 500; cursor: pointer; transition: all 0.2s; text-decoration: none; display: inline-block; text-align: center;"
    when 'secondary'
      "background-color: #{club_secondary_color(club)}; color: #{club_contrast_text(club_secondary_color(club))}; border: 2px solid #{club_primary_color(club)}; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 500; cursor: pointer; transition: all 0.2s; text-decoration: none; display: inline-block; text-align: center;"
    when 'outline'
      "background-color: transparent; color: #{club_primary_color(club)}; border: 2px solid #{club_primary_color(club)}; padding: 0.75rem 1.5rem; border-radius: 8px; font-weight: 500; cursor: pointer; transition: all 0.2s; text-decoration: none; display: inline-block; text-align: center;"
    end
  end

  def club_avatar_style(club, size = '40px')
    "width: #{size}; height: #{size}; border-radius: 50%; display: flex; align-items: center; justify-content: center; color: #{club_contrast_text(club_primary_color(club))}; font-weight: 600; font-size: 0.875rem; background: #{club_gradient(club)};"
  end

  def club_card_accent_style(club)
    "border-top: 4px solid #{club_primary_color(club)};"
  end

  def club_progress_bar_style(club, percentage)
    "background: linear-gradient(to right, #{club_primary_color(club)} #{percentage}%, #e5e7eb #{percentage}%);"
  end

  # Helpers para emojis como ícones
  def football_icon(**options)
    content_tag :span, "⚽", **options
  end

  def trophy_icon(**options)
    content_tag :span, "🏆", **options
  end

  def users_icon(**options)
    content_tag :span, "👥", **options
  end

  def chart_icon(**options)
    content_tag :span, "📊", **options
  end

  def calendar_icon(**options)
    content_tag :span, "📅", **options
  end

  def target_icon(**options)
    content_tag :span, "🎯", **options
  end

  def medal_icon(**options)
    content_tag :span, "🏅", **options
  end

  def trending_up_icon(**options)
    content_tag :span, "📈", **options
  end

  def save_icon(**options)
    content_tag :span, "💾", **options
  end

  def rocket_icon(**options)
    content_tag :span, "🚀", **options
  end

  def trash_icon(**options)
    content_tag :span, "🗑️", **options
  end

  def dice_icon(**options)
    content_tag :span, "🎲", **options
  end

  def arrow_left_icon(**options)
    content_tag :span, "←", **options
  end

  def lightbulb_icon(**options)
    content_tag :span, "💡", **options
  end

  def plus_icon(**options)
    content_tag :span, "+", **options
  end
end