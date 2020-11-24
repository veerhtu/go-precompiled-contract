go-build:
	go build -o goInterface.so -buildmode=c-shared
java-build:
	javac -cp jna-5.6.0.jar Client.java
run:
	java -cp .:jna-5.6.0.jar Client
