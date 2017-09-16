require "./payments/*"
require "kemal"
require "./home"
require "./upload"

module Payments
  get "/" do
    index = Home.new
    index.page
  end

  get "/upload" do
    "Upload Form"
  end

  post "/upload" do |env|
    upload = Upload.new
    filename = upload.save_file(env)
    upload.filter_csv(filename)
    upload.set_percent(env)
    calculate = upload.parse_csv("public/uploads/tmp.csv")
    content = upload.result_in_html(calculate)
    render "src/views/upload.ecr", "src/views/layouts/layout.ecr"
  end
end

Kemal.run
