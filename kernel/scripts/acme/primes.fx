
Primes :: Real -> [Nat]
Primes x := [ p | p |< [2 .. x], IsPrime p]

PrimePi :: Real -> Nat
PrimePi x := Length (Primes x)

Prime :: Nat -> Nat
Prime n :=
    begin
        i <- 0
        k <- 2
        p <- 0
        while i < n do
            if IsPrime k then
                i <- Next i
                p <- k
            k <- Next k
        return p
    end

AsFactor :: (Nat, Nat) -> (Nat, Nat)
AsFactor(r, a) :=
    begin
        s <- 0
        while a Rem r = 0 do
            s <- Next s
            a <- a Quot r
        return(a, s)
    end

PrimeFactors :: Nat -> [(Nat, Nat)]
PrimeFactors n :=
    begin
        if IsPrime n then
            return [(n, 1)]
        else
            r <- []
            for p in Primes(n/2) do
                (n, s) <- AsFactor(p, n)
                if s > 0 then
                    r <- (p, s) >| r
            return r
    end




