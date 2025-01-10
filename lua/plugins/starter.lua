math.randomseed(os.time())
local headers = {
  [[
       ####  #   # #   #   #  
       #   # #  ## # # #  ##  
       ####  # # # # # #   #  
       #   # ##  # # # #   #  
       ####  #   #  ##### ###  
  ]],
  [[
        ___      ___  __     ___  ___   ____    
|"  \    /"  ||" \   |"  \/"  | /  " \   
 \   \  //  / ||  |   \   \  / /__|| |   
  \\  \/. ./  |:  |    \\  \/     |: |   
   \.    //   |.  |    /\.  \    _\  |   
    \\   /    /\  |\  /  \   \  /" \_|\  
     \__/    (__\_|_)|___/\___|(_______) 
                                         
  ]],
  [[
  .-..-..-..-..-. /.
 \  / | | >  <  ||
  `'  `-''-'`-` --
                  
  ]],
}
local function get_random_quote()
  local quotes = {
    [[
A Mathematician is a machine for turning coffee
into theorems.

                                   - Paul Erdos
    ]],
    [[
A comathematician is a machine for turning
cotheorems into ffee.

             - Paul Erdos, on amphetamines
    ]],
    [[
I have hardly ever known a mathematician who
was capable of reasoning.
                                     - Plato
]],
    [[
We'll only use as much category theory as is
necessary. Famous last words…

           - Professor Abramovich, Fall 2010
]],
    [[
These are your father's parentheses. Elegant
weapons, for a more...civilized age.

                                  - xkcd 297
]],
    [[
     ed - text editor

DESCRIPTION
     Ed is the standard text editor.
]],
    [[
Once upon a midnight dreary,
Fingers cramped and vision bleary,
System manuals piled high
And wasted paper on the floor.
]],
    [[
You know what they say, a monad in each hand is,
better than two in the bush... no wait...

                                      - byorgey
]],
    [[
It's not clear that the category of cocoffee is
isomorphic to ffee.
                                       - oerjan
]],
    [[
09 F9 11 02 9D 74 E3 5B D8 41 56 C5 63 56 88 C0
]],
    [[
In the beginning, there were Real Programmers.

                             - Eric S. Raymond
]],
    [[
Baby, my love for you has a proper subgroup
isomorphic to itself.
                                - Evan Chen
]],
    [[
...anyone can do any amount of work, provided
it isn't the work he is supposed to be doing at
that moment.
                              - Robert Benchley
]],
  }

  local index = math.random(#quotes)

  local gap = [[

]]

  return gap .. quotes[index]
end

return {
  "mini.starter",
  after = function()
    require("mini.starter").setup({
      header = headers[math.random(1, #headers)],
      footer = get_random_quote(),
    })
  end,
}
