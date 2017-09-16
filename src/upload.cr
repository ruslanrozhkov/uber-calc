require "csv"

class Upload
  @percent = 5.0

  def save_file(env)
    file = env.params.files["csv_file"]
    filename = file.filename
    # Be sure to check if file.filename is not empty otherwise it'll raise a compile time error
    if !filename.is_a?(String)
      p "No filename included in upload"
    else
      file_path = ::File.join [Kemal.config.public_folder, "uploads/", filename]
      File.open(file_path, "w") do |f|
        IO.copy(file.tmpfile, f)
      end
    end
    filename
  end

  def set_percent(env)
    @percent = env.params.body["percent"].to_f if !env.params.body["percent"].empty?
  end

  def filter_csv(csv_file)
    content = ""
    i = 0
    File.each_line("public/uploads/" + csv_file.to_s) do |line|
      content += line.gsub('"', "") + "\n" if i > 0
      i += 1
    end
    File.write("public/uploads/tmp.csv", content)
  end

  def parse_csv(csv_file)
    payments_array = Array(String | Float64).new
    io = File.open(csv_file)
    csv_array = CSV::Parser.new(io)
    csv_array.each_row do |row|
      row.each do |r|
        payments_array << r
      end
      pay = payment_calculator(row[2].to_f, row[3].to_f, row[4].to_f, row[6].to_f)
      payments_array << pay["total"]
      payments_array << pay["commission"]
      payments_array << pay["pay"]
    end
    payments_array
  end

  def payment_calculator(tarif, bonus, other, cash)
    total = tarif + bonus
    if other > 0
      total += other
    else
      total -= (-other)
    end
    commission = (total * @percent / 100)
    {"total" => total, "commission" => commission, "pay" => (cash - commission)}
  end

  def result_in_html(payments_array)
    html_out = <<-HTML
	<table class="table table-striped">
	<thead>
  	<tr>
    	<th>Водитель</th>
    	<th>Общая стоимость</th>
    	<th>Тарифы без налогов</th>
    	<th>Бонусы</th>
    	<th>Платеж "Прочее"</th>
    	<th>Получено наличными</th>
    	<th>Чистая сумма</th>
    	<th>Общий заработок</th>
    	<th>Комиссия партнера</th>
    	<th>Оплата безнал</th>
  	</tr>
  	</thead>
  	<tboby>
HTML

    i = 0
    payments_array.each do |row|
      html_out += "<tr>" if i == 0
      html_out += "<th>" + row.to_s + "</th>"
      i += 1
      if i == 10
        html_out += "</tr>"
        i = 0
      end
    end
    html_out
  end
end
