module PACKMAN
  class CLI
    @@color_map = {
      :red    => 31,
      :green  => 32,
      :yellow => 33,
      :blue   => 34,
      :purple => 35,
      :cyan   => 36,
      :gray   => 37,
      :white  => 39,
    }

    def self.reset
      escape 0
    end

    def self.width
      `/usr/bin/tput cols`.strip.to_i
    end

    def self.truncate str
      str.to_s[0, width - 4]
    end

    def self.bold str
      "#{escape(1)}#{str}#{escape(0)}"
    end

    def self.color n
      escape "0;#{n}"
    end

    def self.underline n
      escape "4;#{n}"
    end

    def self.escape n
      "\033[#{n}m" if $stdout.tty?
    end

    @@color_map.each do |color_name, color_code|
      self.class_eval(<<-EOT)
        def self.#{color_name} str = nil
          if str
            "\#{#{color_name}}\#{str}\#{reset}"
          else
            color #{color_code}
          end
        end
      EOT
    end

    def self.print_call_stack
      Kernel.caller.each do |stack_line|
        print "#{red '==>'} #{stack_line}\n"
      end
    end

    def self.report_notice message
      print "[#{green 'Notice'}]: #{message}\n"
    end

    def self.report_warning message
      print "[#{yellow 'Warning'}]: #{message}\n"
    end

    def self.report_error message
      print "[#{red 'Error'}]: #{message}\n"
      print_call_stack if PACKMAN::CommandLine.has_option? '-debug'
      exit
    end

    def self.report_check message
      print "[#{red 'CHECK'}]: #{message}\n"
    end

    def self.under_construction!
      print "Oops: PACKMAN is under construction!\n"
      exit
    end

    def self.ask question, possible_answers
      question.split("\n").each do |line|
        print "#{yellow '==>'} #{line}\n"
      end
      print "#{yellow '==>'} Possible answers:\n"
      for i in 0..possible_answers.size-1
        print "    #{CLI.bold i}: #{possible_answers[i]}\n"
      end
    end

    def self.get_answer possible_answers
      while true
        print '> '
        if possible_answers
          begin
            inputs = STDIN.gets.strip.split(/\s/)
            CLI.report_error "You need to input something!" if inputs.empty?
            for i in 0..inputs.size-1
              inputs[i] = Integer(inputs[i])
              if not (0..possible_answers.size-1).cover? inputs[i]
                CLI.report_error "Input in out of range!"
              end
            end
          rescue
            CLI.report_error "Input should be integers!"
          end
          return inputs
        end
      end
    end
  end
end
