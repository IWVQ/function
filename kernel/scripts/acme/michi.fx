...Michi

MakeGrid s :=
    begin
        s0 <- "| " ++ [s{0, 0}] ++ " | " ++ [s{0, 1}] ++ " | " ++ [s{0, 2}] ++ " |"
        s1 <- "| " ++ [s{1, 0}] ++ " | " ++ [s{1, 1}] ++ " | " ++ [s{1, 2}] ++ " |"
        s2 <- "| " ++ [s{2, 0}] ++ " | " ++ [s{2, 1}] ++ " | " ++ [s{2, 2}] ++ " |"
        Print ("    " ++ "+---+---+---+" ++ "    +---+---+---+")
        Print ("    " ++ s0              ++ "    | 1 | 2 | 3 |")
        Print ("    " ++ "+---+---+---+" ++ "    +---+---+---+")
        Print ("    " ++ s1              ++ "    | 4 | 5 | 6 |")
        Print ("    " ++ "+---+---+---+" ++ "    +---+---+---+")
        Print ("    " ++ s2              ++ "    | 7 | 8 | 9 |")
        Print ("    " ++ "+---+---+---+" ++ "    +---+---+---+")
    end

CheckEndGame s :=
    begin
        wx <- "XXX"
        wo <- "OOO"
        sl <- s{0, 0} >| s{0, 1} >| s{0, 2} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{1, 0} >| s{1, 1} >| s{1, 2} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{2, 0} >| s{2, 1} >| s{2, 2} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{0, 0} >| s{1, 0} >| s{2, 0} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{0, 1} >| s{1, 1} >| s{2, 1} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{0, 2} >| s{1, 2} >| s{2, 2} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{0, 0} >| s{1, 1} >| s{2, 2} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        sl <- s{0, 2} >| s{1, 1} >| s{2, 0} >| []
        if sl = wx then
            return 'X'
        elif sl = wo then
            return 'O'
        if  (s{0, 0} = ' ') ||
            (s{0, 1} = ' ') ||
            (s{0, 2} = ' ') ||
            (s{1, 0} = ' ') ||
            (s{1, 1} = ' ') ||
            (s{1, 2} = ' ') ||
            (s{2, 0} = ' ') ||
            (s{2, 1} = ' ') ||
            (s{2, 2} = ' ') then
            return ' '
        else
            return 'E'
    end

Michi() :=
    begin
        player <- 'X'
        winner <- ' '
        state <- ["   ", "   ", "   "]
        MakeGrid state
        while winner = ' ' do
            s <- Input ("Turno " ++ [player] ++ ": ")
            d <- StrToNum(s) - 1
            if (d >= 0) && (d < 9) then
                if state{d Quot 3, d Rem 3} = ' ' then
                    state <- SetElm player [d Quot 3, d Rem 3] state
                    winner <- CheckEndGame state
                    player <- player = 'X'? 'O' ; 'X'
                else
                    Print "Casilla invalida, intente de nuevo"
            else
                Print "Casilla invalida, intente de nuevo"
            MakeGrid state
        if winner = 'E' then
            Print "--- EMPATE ---"
        else
            Print ("GANÓ " ++ [winner])
        Print "Para salir presione Enter"
        Input()
    end
