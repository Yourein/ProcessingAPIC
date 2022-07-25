import java.util.regex.*;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.nio.ByteBuffer;

class AlbumArtExtractor{
    boolean debug = false;

    AlbumArtExtractor(){}
    AlbumArtExtractor(boolean d){
        debug = d;
    }

    //Read %length% bytes from the FileStream. Return as a byte array
    private byte[] readAsByteList(FileInputStream stream, int length){
        byte[] buf = new byte[length];
        try{
            stream.read(buf, 0, length);
        }
        catch (Exception e){
            e.getStackTrace();
        }
        return buf;
    }

    //Read %length% bytes from the FIleStream as ASCII string
    private String readAsAsciiString(FileInputStream stream, int length){
        byte[] data = this.readAsByteList(stream, length);
        String res = "";
        for (byte x : data) res += Character.toString((char)x);

        return res;
    }

    //Read %count% bytes from the FileStream. Return as long since 4bytes array needs unsigned integer.
    private long readAsLong(FileInputStream stream){
        //Read just 1byte default
        return this.readAsLong(stream, 1);
    }

    private long readAsLong(FileInputStream stream, int count){
        byte[] buf = this.readAsByteList(stream, count);
        byte[] res = new byte[8];
        for (byte x : buf) x = 0x00;
        for (byte x : res) x = 0x00;
        
        for (int i = 0; i < count; i++) res[8-count+i] = buf[i];
        return ByteBuffer.wrap(res).getLong();
    }

    //Check whether tag data is ID3v2.3 or not.
    //If the mp3 file has "Extended header", return false;
    public boolean checkVersion(String fPath){
        try{
            FileInputStream f = new FileInputStream(fPath);
            String magicID = this.readAsAsciiString(f, 3);
            long version = this.readAsLong(f, 2);
            long extendedFlag = this.readAsLong(f, 1);
            
            f.close();
            return (magicID.equals("ID3") && version == 0x0300 && (extendedFlag & 0x40) == 0);
        }
        catch (Exception e){
            return false;
        }
    }

    //Return how many skips needed to go to the start byte of the albumart
    private int[] getJpegBegin(FileInputStream rabbit){
        int res = 0;
        byte last = 0, now = 0;

        while(true) {
            last = now;
            try {
                now = byte(rabbit.read());
            }
            catch (Exception e){
                e.getStackTrace();
            }
            res++;
            if (last == byte(-1) && now == byte(-40)) {
                res -= 2;
                break;
            }
        }
        return res;
    }

    private int[] getPngBegin(FileInputStream rabbit){
        int res = 0;
        long[] temp = new long[8];
        for (long x : temp) x = 0;
        final long[] beginFlag = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

        while(true){
            for (int i = 1; i < 8; i++) temp[i-1] = temp[i];
            temp[7] = this.readAsLong(rabbit, 1);
            res[0]++;

            boolean match = true;
            for (int i = 0; i < 8; i++) if (temp[i] != beginFlag[i]) match = false;
            
            if (match){
                res -= 8;
                break;
            }
        }
        return res;
    }

    private int extract(String fPath){
        try {
            FileInputStream rabbit = new FileInputStream(fPath), turtle = new FileInputStream(fPath);
            rabbit.skip(10);
            turtle.skip(10);

            long count = 1;
            while(true){
                String frameName = this.readAsAsciiString(rabbit, 4);
                boolean validName = Pattern.compile("^[A-Z0-9]+$").matcher(frameName).matches();
                if (validName == false) break;
                
                //Get header content-size
                int frameSize = int(this.readAsLong(rabbit, 4));
                
                // Skip flags, sync pos with slower cursor
                rabbit.skip(2);
                turtle.skip(10);

                //If looking frame is "Album Picture" frame
                if (frameName.equals("APIC")){
                    if (debug) println("APIC header found");

                    //Skip some informations, sync pos with slower cursor
                    rabbit.skip(7);
                    turtle.skip(10);
                    String fileFormat = this.readAsAsciiString(rabbit, 3);
                    boolean isJpeg = (fileFormat.equals("jpe")||fileFormat.equals("jpg"));

                    //Find where the Picture starts
                    int sCount;
                    if (isJpeg) {
                        if (debug) println("AlbumArtFormat: jpeg");
                        sCount = this.getJpegBegin(rabbit);
                    }
                    else if (fileFormat.equals("png")) {
                        if (debug) println("AlbumArtFormat: png"); 
                        sCount = this.getPngBegin(rabbit);
                    }
                    else { //Something else, neither jpeg nor png.
                        println("Something Strange found");
                        rabbit.close();
                        turtle.close();
                        return -1;
                    }
                    
                    //Read image
                    byte[] img = new byte[frameSize-slTable[0]];
                    turtle.skip(slTable[0]);
                    turtle.read(img);
                    
                    //Create file
                    String filename = (isJpeg?"out.jpeg":"out.png");
                    FileOutputStream out = new FileOutputStream(sketchPath(filename));
                    out.write(img);

                    //Close streams
                    out.close();
                    out = null;                        
                    rabbit.close();
                    turtle.close();

                    return (isJpeg?1:2);
                }

                //Skip to the end of the frame.
                rabbit.skip(frameSize);
                turtle.skip(frameSize);
                
                //Out Of Range
                if (count > 74) {
                    println("APIC header not found");
                    break;
                }
                count++;
            }

            rabbit.close();
            turtle.close();
        }
        catch (Exception e){
            println(e.getStackTrace());
            e.getStackTrace();
        }
        return -1;
    }

    public int generateAlbumArt(String fPath){
        /* Return Values
            -1: Errors
             1: Jpeg
             2: Png
        */
        if (checkVersion(fPath) == false) return -1;
        else return this.extract(fPath);
    }
}