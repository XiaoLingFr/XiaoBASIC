import std.stdio;
import std.file;
import std.conv;
import std.string;
import eval;

enum type : int {
	integer = 1,
	str 	= 2
};

enum eval_selection : ubyte{
	integer = 0,
	str		= 1
};

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
	ulong program_counter = 0;
	bool main_found = false;

	ulong *main_ptr;

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
	int_variables["debug1"] = 45;
	str_variables["debug2"] = "hello world";

	//just to be lazy I'm just going to find all the labels themselves in the beginning even though I'm doing it anyways in the bottom column
	while(!end){
		char[1] buf;
		file.rawRead(buf);
		char c = buf[0];
		switch(c){
			case '\t':
				break;
			case ';':
				goto case '/';
			case '<':
				goto case '/';
			case '>':
				goto case '/';
			case ':':
				goto case '/';
			case ',':
				goto case '/';
			case '%':
				goto case '/';
			case '"':
				goto case '/';
			case '+':
				goto case '/';
			case '-':
				goto case '/';
			case '*':
				goto case '/';
			case '~':
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
			case '=':
				if(line != ""){
					instruction ~= line;
				}

				if(instruction[instruction.length - 1] == "="){
					instruction[instruction.length - 1] ~= "=";
				}
				else{
					instruction ~= [c];
				}
				line = "";
				break;
			case '\n':

				if(line != ""){
					instruction ~= line;
				}
				line = "";
				
				if(instruction.length > 1 && instruction[1] == ":"){
					string label = instruction[0];
					if(label == "main"){
						main_found = true;
					}
					//next readable byte in the label is always program_counter++
					labels[label] = program_counter + 1;
				}

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
		program_counter++;
		end = file.eof;
	}

	writeln("beginning script");

	//reset the following:
	/*
		string line = "";
		string[] instruction;
		bool end = false;
		ulong program_counter = 0;
		bool main_found = false;
	*/
	line = "";
	instruction = [];
	end = false;

	if(main_found){
		program_counter = labels["main"];
		file.seek(program_counter, 0);
	}
	else{
		writeln("Could not find main");
		return;
	}

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
			case ';':
				goto case '/';
			case '<':
				goto case '/';
			case '>':
				goto case '/';
			case ':':
				goto case '/';
			case '%':
				goto case '/';
			case '"':
				goto case '/';
			case '+':
				goto case '/';
			case '-':
				goto case '/';
			case '*':
				goto case '/';
			case '~':
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
			case '=':
				if(line != ""){
					instruction ~= line;
				}

				if(instruction[instruction.length - 1] == "="){
					instruction[instruction.length - 1] ~= "=";
				}
				else{
					instruction ~= [c];
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

				//ignore labels.
				if(instruction.length == 2 && instruction[1] == ":"){
					goto case_end;
				}

				//then checks for keywords
				switch(instruction[0]){
					//this is a comment
					case ";":
						break;
					//these are operations
					case "input":
						if(instruction.length < 3){
							writeln("Error: not enough operands");
							goto closed_not_nicely;
						}
						if(instruction.length > 3){
							writeln("Error: too many operands");
							goto closed_not_nicely;
						}
						switch(instruction[1]){
							case "str":
								//we need to check if the variable is in int_variables, or else there will be naming conflicts
								long *int_ptr = instruction[2] in int_variables;
								if(int_ptr !is null){
									writeln("Fatal: cannot assign string to int variable");
									goto closed_not_nicely;
								}

								str_variables[instruction[2]] = readln().strip();

								break;
							case "int":
								//we need to check if the variable is in str, or else there will be naming conflicts
								string *str_ptr = instruction[2] in str_variables;
								if(str_ptr !is null){
									writeln("Fatal: cannot assign string to int variable");
									goto closed_not_nicely;
								}

								long temp;
								readf("%d",&temp);
								int_variables[instruction[2]] = temp; 

								break;
							default:
								write("Error: unknown type");
								writeln(instruction[1]);
								goto closed_not_nicely;
						}
						break;
					case "print":
						bool success = print(instruction);
						if(success == false){
							writeln("Error: Syntax error on print statement");
							goto closed_not_nicely;
						}
						break;
					case "call":
						if(instruction.length < 2){
							writeln("Error: Not enough arguments given");
							goto closed_not_nicely;
						}

						if(instruction.length > 2){
							writeln("Error: Too many arguments given.");
							goto closed_not_nicely;
						}

						ulong *address = instruction[1] in labels;
						if(address is null){
							write("Error: ");
							write(instruction[1]);
							write(" is not a valid label");
							writeln();
							goto closed_not_nicely;
						}
						else{
							//push return address onto return address stack
							return_address ~=(program_counter + 1);
							program_counter = *address;
							file.seek(*address,0);
						}
						break;
					case "ret":
						if(return_address.length < 1){
							writeln("Error: Cannot return to function");
							goto closed_not_nicely;
						}
						else{
							//head back
							program_counter = return_address[return_address.length - 1];
							return_address.length--;

							//actually go to the file area
							file.seek(program_counter,0);
						}
						break;
					case "jmp":
						if(instruction.length < 2){
							writeln("Error: operation does not have enough arguments");
							goto closed_not_nicely;
						}

						if(instruction.length > 2){
							writeln("Error: operation has too many arguments");
							goto closed_not_nicely;
						}

						ulong *address_ptr = instruction[1] in labels;
						if(address_ptr is null){
							writeln("Error: label does not exist");
							goto closed_not_nicely;
						}

						program_counter = *address_ptr;
						file.seek(program_counter, 0);
						break;

					case "free":
						free(instruction);
						break;
					default:
						bool valid = eval.eval(labels, int_variables, str_variables, instruction, &program_counter);
						file.seek(program_counter, 0); //stays the same if program counter doesnt change; or else it updates the program counter

						if(!valid){
							writeln("Error: Operation not recognized");
							goto closed_not_nicely;
						}
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
		program_counter++;

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

bool free(string[] instruction){
	if(instruction.length != 2){
		writeln("Error: invalid combination of instructions.");
		return false;
	}
	int_variables.remove(instruction[1]);
	str_variables.remove(instruction[1]);
	//writeln("free cleared"); //debug
	return true;
}

bool print(string[] instruction){
	string temp = "";
	int quote_count = 0;
	ulong index = 0;

	string *str_ptr;
	long *long_ptr;

	//check if a variable, if not, remove it
	if(instruction.length == 2){
		instruction.length = 4;
		//writeln("allocation cleared"); //debug
		str_ptr = instruction[1] in str_variables;
		if(str_ptr !is null){
			instruction[1] = "\"";
			instruction[2] = *str_ptr;
			instruction[3] = "\"";
			goto print_continue;
		}

		//writeln("string cleared"); //debug

		long_ptr = instruction[1] in int_variables;
		long temp_def; 
		if(long_ptr !is null){
			temp_def = *long_ptr;
			instruction[1] = "\"";
			instruction[2] = temp_def.to!string;
			instruction[3] = "\"";
			goto print_continue;
		}
		
		//writeln("integer cleared"); //debug

		variable_print_failed:
		writeln("Error: Variable does not exist");
		return false;
	}

	print_continue:
	//writeln(instruction); //debug

	if(instruction.length < 3){
		writeln("Error: Invalid combination of arguments for print");
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
		writeln("Error: Improper usage of built-in function print");
		return false;
	}
	writeln(temp);
	if(index < instruction.length - 1){
		return false;
	}
	return true;
}


void error(string[] instruction){
	string temp = "";
	write("Error: Invalid instruction at instruction ");
	for(int i = 0; i < instruction.length; i++){
		temp ~= instruction[i];
		temp ~= " ";
	}
	write(temp);
	writeln();
	return;
}