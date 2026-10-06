How to Play screenshots and videos
==================================
Put files here and name them in the workbook's "How To Play" tab
(Screenshot and Video columns), WITHOUT the extension.

  Screenshot "battle_hand"  ->  assets/howto/battle_hand.png
  Video      "turn_demo"    ->  assets/howto/turn_demo.ogv

Screenshots: PNG, ideally the game's own 1080 wide.
Videos: Ogg Theora (.ogv) ONLY. Godot plays no other video format on
iOS and Android, so mp4 and webm will not work. Convert with, for example:

  ffmpeg -i demo.mp4 -c:v libtheora -q:v 6 -an demo.ogv

(-an drops the audio track; remove it to keep sound, Vorbis audio is supported.)
A name that has no file here shows a grey placeholder labelled with the
file it is waiting for.
