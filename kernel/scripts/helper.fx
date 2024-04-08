
ShowBasicHelp :: () -> ()
ShowBasicHelp() :=
    begin
        Print "+    is for adding numbers"
        Print "-    is for substracting numbers"
        Print "*    is for multiplying numbers"
        Print "/    is for dividing numbers"
        Print "^    is for powering numbers"
    end

ShowAbout :: () -> ()
ShowAbout() :=
    begin
        Print "*************************************************************"
        Print "*                       Function [v0.5]                     *"
        Print "*     Copyright(c) 2023-2024 Ivar Wiligran Vilca Quispe     *"
        Print "*                                                           *"
        Print "* Function es un software diseñado para programar funciones *"
        Print "* y algoritmos de manera facil y elegante.                  *"
        Print "*************************************************************"
    end
    
ShowVersion() :=
    begin
        Print "Function [v0.5]"
    end

ShowShortcuts() :=
    begin
        Print "Ctrl+BREAK       to intterupt ejecucion"
    end

SelectOption :: String -> ()
SelectOption s :=
    begin
        if s = "basic" then
            ShowBasicHelp()
        elif s = "about" then
            ShowAbout()
        elif s = "version" then
            ShowVersion()
        elif s = "shortcuts" then
            ShowShortcuts()
        else
            Print "invalid help option"
    end

ShowOptions :: () -> ()
ShowOptions() :=
    begin
        Print "type one of this options:\n"
        Print "basic        show the basic help"
        Print "about        show the about splash"
        Print "version      show the about splash"
        Print "shortcuts    show the avilable shortcuts"
        Print "quit         exit from help utility"
    end

Help :: () -> ()
Help() := 
    begin
        Print "Bienvenido al entorno de ayuda de Function v0.5"
        Print "Vease tambien:"
        Print "    doc\\Manual.pdf    Para un completo aprendizaje"
        Print "    doc\\Reference.pdf Para las referencias"
        Print "\n"
        ShowOptions()
        break <- false
        while ~break do
            Print "\n"
            s <- Input "help> "
            if s = "quit" then
                break <- true
            else
                SelectOption s
        Print "Closing Function help utility"
    end
