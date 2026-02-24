# frozen_string_literal: true

module Yobi
  module UI
    # Simple terminal progress bar
    class Progress
      BAR_WIDTH = 40

      STYLE = {
        arrow: { complete: "▸", incomplete: "▹", unknown: "◂▸" },
        asterisk: { complete: "✱", incomplete: "✳", unknown: "✳✱✳" },
        blade: { complete: "▰", incomplete: "▱", unknown: "▱▰▱" },
        block: { complete: "█", incomplete: "░", unknown: "░█░" },
        box: { complete: "■", incomplete: "□", unknown: "□■□" },
        bracket: { complete: "❭", incomplete: " ", unknown: "❬=❭" },
        burger: { complete: "≡", incomplete: " ", unknown: "<≡>" },
        button: { complete: "⦿", incomplete: "⦾", unknown: "⦾⦿⦾" },
        chevron: { complete: "›", incomplete: " ", unknown: "‹=›" },
        circle: { complete: "●", incomplete: "○", unknown: "○●○" },
        classic: { complete: "=", incomplete: " ", unknown: "<=>" },
        crate: { complete: "▣", incomplete: "⬚", unknown: "⬚▣⬚" },
        diamond: { complete: "♦", incomplete: "♢", unknown: "♢♦♢" },
        dot: { complete: "･", incomplete: " ", unknown: "･･･" },
        heart: { complete: "♥", incomplete: "♡", unknown: "♡♥♡" },
        star: { complete: "★", incomplete: "☆", unknown: "☆★☆" }
      }.freeze

      def initialize(total_bytes = nil, options = { style: :block })
        @total = total_bytes
        @downloaded = 0
        @last_draw = Time.now
        @options = options
      end

      def increment(bytes)
        @downloaded += bytes
        current_time = Time.now

        return unless current_time - @last_draw >= 0.1 || finished?

        draw
        @last_draw = current_time
      end

      def finished?
        @total && @downloaded >= @total
      end

      def draw
        if @total
          percent = @downloaded.to_f / @total
          filled  = (percent * BAR_WIDTH).round
          bar = theme[:complete] * filled + theme[:incomplete] * (BAR_WIDTH - filled)
          print "\r[#{bar}] #{(percent * 100).round(1)}% "\
                "(#{human(@downloaded)}/#{human(@total)})"
        else
          print "\r#{human(@downloaded)} downloaded"
        end

        $stdout.flush
      end

      private

      def theme
        STYLE[@options[:style]] || STYLE[:box]
      end

      def human(bytes)
        if bytes > 1_048_576
          format("%.2f MiB", bytes / 1_048_576.0)
        elsif bytes > 1024
          format("%.2f KiB", bytes / 1024.0)
        else
          "#{bytes} B"
        end
      end
    end
  end
end
