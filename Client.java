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
        ByteBuffer buffer = ByteBuffer.wrap(b);
        return buffer.getLong();
    }
    public static int toInt(byte[] b) {
        ByteBuffer buffer = ByteBuffer.wrap(b);
        return buffer.getInt();
    }

   static public void main(String argv[]) {
        GoInterface GoInterface = (GoInterface) Native.loadLibrary(
            "./goInterface.so", GoInterface.class);

        byte[] arr = "Hello Java!".getBytes();
        Pointer ptr = new Memory(arr.length);
        ptr.write(0, arr, 0, arr.length);

        long gas = GoInterface.GetGasForData(ptr, arr.length);
        Pointer rarr = GoInterface.Run(ptr, arr.length);
        int length = toInt(rarr.getByteArray(3, 7));
        long time = toLong(rarr.getByteArray(7, length));
        System.out.printf("%d\n%d\n", gas, time);         
    }
}
