class ConfigFile
    def self.process(file)
        config_list = []
        File.open(file).each do |line|
            config_list << /: (\d+)/.match(line)[1]
        end
        config_list
    end

    def self.process_term_dates(file="")
        term_dates = { 1 => "", 2 => "", 3 => "", 4 => "", 5 => "", 6 => "", 7 => "", 8 => "", 9 => "", 10 => "", 11 => "" }
        array = []

        if (file != "")
            File.readlines(file).each do |line|
                array << /: (.+)/.match(line)[1]
            end

            array.each_with_index do |date, index|
                term_dates[index + 1] = date
            end
            term_dates
            
        else
            term_dates
        end
    end


end


class String
    # colorization
    def colorize(color_code)
        "\e[#{color_code}m#{self}\e[0m"
    end
    
    def red
        colorize(31)
    end
    
    def green
        colorize(32)
    end
    
    def yellow
        colorize(33)
    end
        
    def pink
        colorize(35)
    end
end


class Course

    def initialize(course_id, mechanize, term_dates)
        @course_id = course_id
        @mechanize = mechanize
        @term_dates = term_dates
        
        entry_point
        get_name
    end

    def entry_point
        @entry_point = "https://learn.dcollege.net/webapps/blackboard/execute/announcement?method=search&context=course&course_id=_#{@course_id}_1&handle=cp_announcements&mode=cpview"
    end


    def get_name
        @mechanize.get(@entry_point) do |page|
            @name = page.link_with(:id => 'courseMenu_link')
        end
    end

    def time_content_areas
        @mechanize.get(@entry_point) do |page|
            @links = page.links_with(:text => /[week|unit] \d+$/i)
        end
        
        if (@links.length == 0)
            puts "#@{name} - No valid weeks found. Checking for 'One' vs '1' now.".pink
            @mechanize.get(@entry_point) do |page|
                @links = page.links_with(:text => /(week|unit) (one|two|three|four|five|six|seven|eight|nine|ten|eleven)$/i)
            end
        end
            

        if (@links.length == 0 || @links.length < 9)
            puts "#{@name} - No timeable weeks.".red
        end
        
        puts "#{@name} - Successfully built link list. Timing course now.".green

        @links.each do |week_link|

            content_id = /content_id=_(\d+)/.match(week_link.href)[1]
            form_url = "https://learn.dcollege.net/webapps/blackboard/content/manageFolder.jsp?content_id=_#{content_id}_1&course_id=_#{@course_id}_1"
            
            
            if week_link.text =~ (/(week|unit) one/i)
                week_link = week_link.text.sub("One", "1")
            elsif week_link.text =~ (/(week|unit) two/i)
                week_link = week_link.text.sub("Two", "2")
            elsif week_link.text =~ (/(week|unit) three/i)
                week_link = week_link.text.sub("Three", "3")
            elsif week_link.text =~ (/(week|unit) four/i)
                week_link = week_link.text.sub("Four", "4")
            elsif week_link.text =~ (/(week|unit) five/i)
                week_link = week_link.text.sub("Five", "5")
            elsif week_link.text =~ (/(week|unit) six/i)
                week_link = week_link.text.sub("Six", "6")
            elsif week_link.text =~ (/(week|unit) seven/i)
                week_link = week_link.text.sub("Seven", "7")
            elsif week_link.text =~ (/(week|unit) eight/i)
                week_link = week_link.text.sub("Eight", "8")
            elsif week_link.text =~ (/(week|unit) nine/i)
                week_link = week_link.text.sub("Nine", "9")
            elsif week_link.text =~ (/(week|unit) ten/i)
                week_link = week_link.text.sub("Ten", "10")
            elsif week_link.text =~ (/(week|unit) eleven/i)
                week_link = week_link.text.sub("Eleven", "11")
            end
            
            week_number = /[week|unit] (\d+)/i.match(week_link)[1]

            @mechanize.get(form_url) do |form_page|

                form_page.form_with(:name => 'the_form') do |f|
                    f.checkbox_with(:name => "bbDateTimePicker_start_checkbox").value = 1
                    f.checkbox_with(:name => "bbDateTimePicker_start_checkbox").check
                    f.bbDateTimePicker_start_datetime = @term_dates[week_number.to_i]
                    f.submit(f.buttons[1])
                end
            end
            puts "#{@name} - changed date for week #{week_number} to #{@term_dates[week_number.to_i]}".green
        end

    end


end


