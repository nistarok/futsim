module.exports = {
  content: [
    './app/views/**/*.html.erb',
    './app/helpers/**/*.rb',
    './app/assets/stylesheets/**/*.css',
    './app/javascript/**/*.js'
  ],
  theme: {
    extend: {
      colors: {
        'brasil-green': '#228B22',
        'brasil-blue': '#0047AB',
        'brasil-yellow': '#FFD700',
        'field-green': '#2d5a2d'
      },
      fontFamily: {
        sans: ['-apple-system', 'BlinkMacSystemFont', 'Segoe UI', 'Roboto', 'sans-serif']
      },
      animation: {
        'pulse-live': 'pulse 2s infinite',
        'spin-slow': 'spin 3s linear infinite',
        'rainbow': 'hue-rotate 3s linear infinite'
      },
      gradientColorStops: {
        'brasil-green': '#228B22',
        'brasil-green-dark': '#1e7b1e'
      }
    }
  },
  plugins: []
}