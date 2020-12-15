package main

// #include <stdlib.h>
import "C"
import (
	"encoding/binary"
	"sync"
	"time"
	"unsafe"
)

var mtx sync.Mutex

//export Java_GoJni_getGasForData
func Java_GoJni_getGasForData(ptr unsafe.Pointer, len C.int) uint64 {
	mtx.Lock()
	defer mtx.Unlock()
	return getGasForData(C.GoBytes(ptr, len))
}

//export Java_GoJni_run
func Java_GoJni_run(ptr unsafe.Pointer, len C.int) unsafe.Pointer {
	mtx.Lock()
	defer mtx.Unlock()
	rarr := run(C.GoBytes(ptr, len))
	cArr := C.CBytes(rarr)
	return cArr
}
func main() {}

/*///////////////////////////////////////////////////////////////////////////////
WARNING: DON'T MODIFY UPPER PART. QA TESTER WILL GENERATE AN ERROR AFTER SUBMSSTION
ONLY IMPORT SECTION CAN BE MODIFIED.
/////////////////////////////////////////////////////////////////////////////////*/

// getGasForData - Returns back gas required to execute the contract
func getGasForData([]byte) uint64 {
	// calculate gas here
	return uint64(5000000)
}

// run - Runs the contract, It recieve data as parsed byte and returns back a parsed byte array
func run(arr []byte) []byte {
	// Example of returning time in byte array
	timeBytes := make([]byte, 8)
	now := uint64(time.Now().UTC().UnixNano())
	binary.BigEndian.PutUint64(timeBytes, now)
	return getBytes(timeBytes, nil)
}

func getBytes(msg []byte, err error) []byte {
	msgLenBytes := make([]byte, 4)
	if err != nil {
		binary.BigEndian.PutUint32(msgLenBytes, uint32(len(err.Error())))
		return append(append([]byte{0, 253, 253}, msgLenBytes...), []byte(err.Error())...)
	}
	binary.BigEndian.PutUint32(msgLenBytes, uint32(len(msg)))
	return append(append([]byte{1, 253, 253}, msgLenBytes...), msg...)
}
