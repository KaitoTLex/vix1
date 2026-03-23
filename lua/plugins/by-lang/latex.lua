return {
  "texpresso.vim",
  after = function()
    require("texpresso").texpresso_path = nixCats("bin.texpresso")
  end,
}
