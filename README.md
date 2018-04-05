# CSCB58 Project

# What is this?

This is a game we created as part of a project for CSCB58 Winter 2018. It is coded in Verilog HDL, and is originally meant to run on the Altera DE2-115 FPGA Board. Also uses a VGA Display.

---

# Who made this?

This was made by our team of 4
- Mustafa Quraish
- Michael Sun
- Seemin Syed
- Lan Yao

---

# Controls

*Directions similar to Vim, for the familiar*

`KEY[0]` - Right

`KEY[1]` - Up

`KEY[2]` - Down

`KEY[3]` - Left

---

`SW [17:16]` - Toggle between 3 speeds - one frame of animation every 1000000, 750000, and 500000 cycles respectively, with a clock speed of 50Mhz.

`SW[15]` - Used to reset the game when you run out of lives

`SW[5:0]` - Use to enable bees. One bee per switch.

---

`HEX0` - Displays Lives

`HEX5, HEX4` - Current score

`HEX7, HEX6` - High Score

# Running the Game

If you have the same board used in the making of this project, you can simply write the precompiled `bounce.sof` in the output_files folder.

If not, clone the repo, open the project in Quartus with `bounce.qpf` and import your pin assignment files. Be warned, the top-level module is quite large as we didn't get enough time to seperate everything out into modules, so it may take a couple minutes refactoring if your inputs are named differently on another board.

# Online version

If you don't have an FPGA or don't want to mess around with Quartus, I've developed an online version of the game in JavaScript. It keeps all the graphics, colors, and everything else intact, except that the score needs to be displayed on the screen because it was done on the Hex Display.

The Github page for it which also describes the controls can be found [here](http://github.com/mustafaquraish/TheBeesGame) 
