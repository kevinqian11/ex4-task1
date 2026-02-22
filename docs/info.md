<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

Takes a magnitude comparison between each new serial value and the current min and max values, and updates the
min and max values accordingly. Subtracts the max and min values to obtain the range output.

## How to test

On the clock edge where go is asserted and every clock edge after, up until (and including) the edge where finish is asserted, RangeFinder will look at the data_in value and determine which is the largest and which is the smallest
(these are unsigned values). Output on range is the difference between the largest and smallest.
