import com.sun.jna.*;
import java.util.*;
import java.lang.Long;
import java.nio.ByteBuffer;

public class Client {
   public interface GoInterface extends Library {
        public Pointer Run(Pointer p , int len);
        public long GetGasForData(Pointer p , int len);
    }
 
    public static long toLong(byte[] b) {
        ByteBuffer bb = ByteBuffer.allocate(b.length);
        bb.put(b);
        return bb.getLong();
    }

   static public void main(String argv[]) {
        GoInterface GoInterface = (GoInterface) Native.loadLibrary(
            "./goInterface.so", GoInterface.class);

        byte[] arr = "Hello Java!".getBytes();
        Pointer ptr = new Memory(arr.length);
        ptr.write(0, arr, 0, arr.length);

        Pointer rarr = GoInterface.Run(ptr, arr.length);
        ByteBuffer buffer = ByteBuffer.wrap(rarr.getByteArray(0, 8));
        long t = buffer.getLong();
        long gas = GoInterface.GetGasForData(ptr, arr.length);
        System.out.printf("%d\n%d\n", t, gas) ;
         
    }
}
