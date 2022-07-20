AlbumArtExtractor e = new AlbumArtExtractor();
AlbumArtExtractor eDebug = new AlbumArtExtractor(true);

PImage albumArt;

void setup(){
  size(500, 500);
  
  int check = e.generateAlbumArt("C:\\hogehoge\\fugafuga.mp3");
  
  if (check == -1) albumArt = null;
  else if (check == 1) albumArt = loadImage("out.jpeg");
  else if (check == 2) albumArt = loadImage("out.png");
}

void draw(){
  if (albumArt != null) image(albumArt, 500, 500);
}
