module LineupsHelper
  def position_style(position, index)
    positions = {
      'GK' => { top: '85%', left: '50%' },
      'CB' => [
        { top: '70%', left: '40%' },
        { top: '70%', left: '60%' }
      ],
      'LB' => { top: '70%', left: '15%' },
      'RB' => { top: '70%', left: '85%' },
      'CDM' => [
        { top: '55%', left: '35%' },
        { top: '55%', left: '65%' }
      ],
      'CM' => [
        { top: '45%', left: '30%' },
        { top: '45%', left: '50%' },
        { top: '45%', left: '70%' }
      ],
      'CAM' => [
        { top: '35%', left: '40%' },
        { top: '35%', left: '50%' },
        { top: '35%', left: '60%' }
      ],
      'LM' => { top: '50%', left: '10%' },
      'RM' => { top: '50%', left: '90%' },
      'LW' => { top: '20%', left: '20%' },
      'RW' => { top: '20%', left: '80%' },
      'ST' => [
        { top: '15%', left: '40%' },
        { top: '15%', left: '50%' },
        { top: '15%', left: '60%' }
      ]
    }

    position_data = positions[position]
    if position_data.is_a?(Array)
      style_data = position_data[index % position_data.length] || position_data[0]
    else
      style_data = position_data || { top: '50%', left: '50%' }
    end

    "top: #{style_data[:top]}; left: #{style_data[:left]}; transform: translate(-50%, -50%);"
  end
end
