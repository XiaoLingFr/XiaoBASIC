module eval;

import std.stdio;
import std.file;
import std.conv;

//using reverse polish notation
bool eval(ulong[string] labels, long[string] int_variables, string[string] str_variables, string[] instructions, ulong* program_counter){
    //some keys to consider:
    /*
        blt :   branch if less than
        bgt :   branch if greater than
        beq :   branch if equal
        ble :   branch if less than or equal
        bge :   branch if greater than or equal

        all will be <condition> <operand 1> <operand2> <label>
    */

    //string concatenation
    if(instructions.length == 5 && instructions[1] == "=" && instructions[3] == "~"){
        if(str_variables[instructions[0]] !is null && str_variables[instructions[0]] !is null && str_variables[instructions[0]] !is null){
            str_variables[instructions[0]] = str_variables[instructions[2]] ~ str_variables[instructions[4]];
        }
        else{
            end_horribly();
        }
        return true;
    }

    //string assignment
    if(instructions.length >=3 && instructions[1] == "@"){
        //check if variable has already been declared as an integer
        long *int_ptr = instructions[0] in int_variables;
        if(int_ptr !is null){
            end_horribly();
        }
    
        //iterate over and replace
        ulong ptr = 2;
        string temp;
        ulong counter = 0;
        while(ptr < instructions.length){
            if(instructions[ptr] == "\""){
                counter = counter + 1;
                counter = counter % 2;
            }
            else{
                switch(counter){
                    case 1: //insider quotes
                        temp ~= instructions[ptr];
                        temp ~= " ";
                        break;
                    default:
                        string *str_ptr = instructions[ptr] in str_variables;
                        if(str_ptr is null){
                            int_ptr = instructions[ptr] in int_variables;
                            if(int_ptr !is null){
                                temp ~= (*int_ptr).to!string;
                                temp ~= " ";
                            }
                            else{
                                end_horribly();
                            }
                        }
                        else{
                            temp ~= *str_ptr;
                            temp ~= " ";
                        }
                        break;
                }
            }
            ptr = ptr + 1;
        }

        str_variables[instructions[0]] = temp;

        return true;
    }

    //assignment with operations
    if(instructions.length >= 3 && instructions[1] == "="){
        long *str_ptr = instructions[0] in int_variables;
        if(str_ptr !is null){
            end_horribly();
        }

        string variable = instructions[0];
        string[] evaluate = instructions[2 .. $];

        //iterate over and replace with variable values
        for(int i = 0; i<evaluate.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }

        //pass to eval_expr()
        long answer = eval_expr(evaluate);

        int_variables[variable] = answer;
        return true;
    }

    //check branching comparison
    if(instructions.length == 4 && instructions[0] == "blt"){
        for(int i = 0; i<instructions.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }
        if(instructions[1].to!long < instructions[2].to!long){
            ulong *label_ptr = (instructions[3] in labels);
            if(label_ptr is null){
                end_horribly();
            }
            else{
                *program_counter = *label_ptr;
            }
        }
        return true;
    }

    if(instructions.length == 4 && instructions[0] == "bgt"){
        for(int i = 0; i<instructions.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }
        if(instructions[1].to!long > instructions[2].to!long){
            ulong *label_ptr = (instructions[3] in labels);
            if(label_ptr is null){
                end_horribly();
            }
            else{
                *program_counter = *label_ptr;
            }
        }
        return true;
    }

    if(instructions.length == 4 && instructions[0] == "beq"){
        for(int i = 0; i<instructions.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }
        if(instructions[1].to!long == instructions[2].to!long){
            ulong *label_ptr = (instructions[3] in labels);
            if(label_ptr is null){
                end_horribly();
            }
            else{
                *program_counter = *label_ptr;
            }
        }
        return true;
    }

    if(instructions.length == 4 && instructions[0] == "ble"){
        for(int i = 0; i<instructions.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }
        if(instructions[1].to!long <= instructions[2].to!long){
            ulong *label_ptr = (instructions[3] in labels);
            if(label_ptr is null){
                end_horribly();
            }
            else{
                *program_counter = *label_ptr;
            }
        }
        return true;
    }

    if(instructions.length == 4 && instructions[0] == "bge"){
        for(int i = 0; i<instructions.length; i++){
            long *var_ptr = instructions[i] in int_variables;
            if(var_ptr !is null){
                instructions[i] = (*var_ptr).to!string;
            }
        }
        if(instructions[1].to!long >= instructions[2].to!long){
            ulong *label_ptr = (instructions[3] in labels);
            if(label_ptr is null){
                end_horribly();
            }
            else{
                *program_counter = *label_ptr;
            }
        }
        return true;
    }

    return false;
}

long eval_expr(string[] expr){
    long[] stack;
    for(ulong i = 0; i < expr.length; i++){
        if( expr[i] != "+" &&
            expr[i] != "-" &&
            expr[i] != "*" &&
            expr[i] != "/" &&
            expr[i] != "%"
        ){
            stack ~= expr[i].to!long;
            goto end_evaluation_current_index;
        }

        //check if argument is an operation before continuing;
        if(stack.length < 2 && (expr[i] == "+" || expr[i] == "-"|| expr[i] == "*" || expr[i] == "/" || expr[i] == "%")){
            writeln("not enough number arguments were given.");
            end_horribly();
        }
        
        switch(expr[i]){
            case "+":
                stack[stack.length - 2] = stack[stack.length - 2] + stack[stack.length - 1];
                stack.length = stack.length - 1;
                break;
            case "-":
                stack[stack.length - 2] = stack[stack.length - 2] - stack[stack.length - 1];
                stack.length = stack.length - 1;
                break;
            case "*":
                stack[stack.length - 2] = stack[stack.length - 2] * stack[stack.length - 1];
                stack.length = stack.length - 1;
                break;
            case "/":
                stack[stack.length - 2] = stack[stack.length - 2] / stack[stack.length - 1];
                stack.length = stack.length - 1;
                break;
            case "%":
                stack[stack.length - 2] = stack[stack.length - 2] % stack[stack.length - 1];
                stack.length = stack.length - 1;
                break;
            default:
                write("Error: could not parse expression: ");
                writeln(expr[i]);
                end_horribly();
        }
        end_evaluation_current_index:
    }

    if(stack.length != 1){
        writeln("expression has gone wrong");
        end_horribly();
    }

    return stack[0];
}

void end_horribly(){
    throw new Exception("Could not continue evaluation");
    return; //this is not returning lmao
}