import std.stdio;
import std.file;
import std.conv;

enum type : int {
	integer = 1,
	str 	= 2
}

//this will be where we get the stuff lmao.
ulong[string] labels;

//variables
long[string] int_variables;
string[string] str_variables;

void main(string[] args)
{
	File file;
	string filename;
	string line = "";
	string[] instruction;
	bool end = false;
	ulong counter = 0;
	bool main_found = false;

	ulong[] return_address;

	if(args.length != 2){
		writeln("invalid amount of arguments given");
		goto exit;
	}

	filename = getcwd() ~ "/" ~ args[1];

	if(!exists(filename)){
		writeln("Script does not exist.");
		goto exit;
	}

	if(isDir(filename)){
		writeln("Script is a directory.");
		goto exit;
	}

	if(isSymlink(filename)){
		writeln("Script is a Link.");
		goto exit;
	}

	try{
		file = File(filename, "r");
	}
	catch(FileException FE){
		writeln("Could not acccess file");
	}

	//insert some debug variables
	//int_variables["debug1"] = 45;
	//str_variables["debug2"] = "hello world";

	//XiaoBASIC expects a main label
	while(!end){
		//writeln(line); //debug
		//writeln(instruction); //debug

		//traverse each byte
		//skips over: \t
		//creates a new split on: < > ( ) : , " " + - * /
		//terminates read on \n EOF
		char[1] buf;
		file.rawRead(buf);
		char c = buf[0];
		switch(c){
			case '\t':
				break;
			case '<':
				goto case '/';
			case '>':
				goto case '/';
			case '(':
				goto case '/';
			case ')':
				goto case '/';
			case ':':
				goto case '/';
			case ',':
				goto case '/';
			case '"':
				goto case '/';
			case '+':
				goto case '/';
			case '-':
				goto case '/';
			case '*':
				goto case '/';
			case '/':
				//commit current string to instruction and then add the current string to instruction and commit as well
				if(line != ""){
					instruction ~= line;
				}
				line = "";
				instruction ~= [c];
				break;
			case ' ':
				if(line != ""){
					instruction ~= line;
				}
				line = "";
				break;
			case '\n':
				if(line != ""){
					instruction ~= line;
				}
				line = "";

				if(instruction.length == 0){
					goto eval_exit;
				}

				//evaluate expression in instruction;
				//writeln(instruction); //debug
				//XiaoBASIC always first checks if the argument is a label
				if(instruction.length > 1 && instruction[1] == ":"){
					if(instruction[0] == "main"){
						main_found = true;
					}
					//next readable byte in the label is always counter++
					labels[instruction[0]] = counter + 1;
					instruction = [];
					line = "";
					goto eval_exit;
				}

				//if main isn't found, XiaoBASIC stops evalutating to stop wasting time
				if(!main_found){
					instruction = [];
					line = "";
					goto eval_exit;
				}

				//then checks for keywords
				switch(instruction[0]){
					case "print":
						bool success = print(instruction);
						if(success == false){
							writeln("Syntax error on print statement");
							goto closed_not_nicely;
						}
						break;
					case "call":
						if(instruction.length < 2){
							writeln("Not enough arguments given");
							goto closed_not_nicely;
						}

						if(instruction.length > 2){
							writeln("Too many arguments given.");
							goto closed_not_nicely;
						}

						ulong *address = instruction[1] in labels;
						if(address is null){
							write(instruction[1]);
							write(" is not a valid label");
							writeln();
							goto closed_not_nicely;
						}
						else{
							//push return address onto return address stack
							return_address ~=(counter + 1);
							file.seek(*address,0);
						}
						break;
					case "ret":
						if(return_address.length < 1){
							writeln("Cannot return to function");
							goto closed_not_nicely;
						}
						else{
							//head back
							counter = return_address[return_address.length - 1];
							return_address.length--;

							//actually go to the file area
							file.seek(counter,0);
						}
						break;
					default:
						writeln("Operation not recognized");
						goto closed_not_nicely;
						break;
				}

				if(file.eof){
					end = true;
				}
				
				case_end:

				//clear the buffer
				instruction = [];
				line = "";

				break;
			default:
				if(file.eof){
					goto case '\n';
				}
				else{
					line ~= [c];
				}
		}
		eval_exit:
		counter++;

		if(file.eof){
			goto closed_nicely;
		}
	}
	
	goto closed_nicely;

	closed_not_nicely:
	error(instruction);

	closed_nicely:
	file.close();

	exit:
	return;
}
void free(string[] instruction){
	return;
}

bool print(string[] instruction){
	string temp = "";
	int quote_count = 0;
	ulong index = 0;

	string *str_ptr;
	long *long_ptr;

	//check if a variable, if not, remove it
	if(instruction.length == 2){
		str_ptr = instruction[1] in str_variables;
		if(str_ptr !is null){
			instruction[1] = "\"";
			instruction ~= [*str_ptr];
			instruction ~= "\"";
			goto print_continue;
		}

		long_ptr = instruction[1] in int_variables;
		long temp_def = *long_ptr;
		if(long_ptr !is null){
			instruction[1] = "\"";
			instruction ~= temp_def.to!string;
			instruction ~= "\"";
			goto print_continue;
		}

		variable_print_failed:
		writeln("Improper usage of variable print");
		return false;
	}

	print_continue:
	//writeln(instruction); //debug

	if(instruction.length < 3){
		writeln("Invalid combination of arguments for print");
		return false;
	}

	for(ulong i = 1; i<instruction.length && quote_count < 2; i++){
		if(instruction[i] != "\""){
			temp ~= instruction[i];
			temp ~= " ";
		}
		else{
			quote_count++;
		}

		if(quote_count == 2){
			index = i;
		}
	}
	if(quote_count < 2){
		writeln("Improper usage of built-in function print");
		return false;
	}
	writeln(temp);
	if(index < instruction.length - 1){
		return false;
	}
	return true;
}

//only applies to variable assignment
int eval_assignment(string[] instruction){

	//an expression might look like this:
	//	x = ((4+5)*3 - 2)									<- valid
	//	s = "wsggggggg" 									<- valid
	//	b = (4 < 5) 										<- if true, it returns 1, if false, it returns 0
	//	i = ("wsggg" + 1) 									<- invalid
	//	i2 = (1 + "1") 										<- invalid
	//first thing's first, an expression will always

	string target = instruction[0];

	

	return true;
}

void error(string[] instruction){
	string temp = "";
	write("Invalid instruction at instruction ");
	for(int i = 0; i < instruction.length; i++){
		temp ~= instruction[i];
		temp ~= " ";
	}
	write(temp);
	writeln();
	return;
}