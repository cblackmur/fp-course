{-# LANGUAGE NoImplicitPrelude #-}
{-# LANGUAGE ScopedTypeVariables #-}
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE RebindableSyntax #-}

module Course.FileIO where

import Course.Core
import Course.Applicative
import Course.Apply
import Course.Bind
import Course.Functor
import Course.List

{-

Useful Functions --

  getArgs :: IO (List Chars)
  putStrLn :: Chars -> IO ()
  readFile :: Chars -> IO Chars
  lines :: Chars -> List Chars
  void :: IO a -> IO ()

Abstractions --
  Applicative, Monad:

    <$>, <*>, >>=, =<<, pure


  -- sequenceIO

Problem --
  Given a single argument of a file name, read that file,
  each line of that file contains the name of another file,
  read the referenced file and print out its name and contents.

Example --
Given file files.txt, containing:
  a.txt
  b.txt
  c.txt

And a.txt, containing:
  the contents of a

And b.txt, containing:
  the contents of b

And c.txt, containing:
  the contents of c

$ runhaskell io.hs "files.txt"
============ a.txt
the contents of a

============ b.txt
the contents of b

============ c.txt
the contents of c

-}

-- sequenceIO :: List (IO a) -> IO (List a)
-- sequenceIO = ???

-- /Tip:/ use @getArgs@ and @run@
main ::
  IO ()
main =
  getArgs >>= traversey_ run

void_ :: IO a -> IO ()
void_ io = (\_ -> ()) <$> io

traversey_ :: (a -> IO b) -> List a -> IO ()
traversey_ f as = traversey f as >>= \_ -> pure ()

traversey :: (a -> IO b) -> List a -> IO (List b)
traversey f = sequenceIO . map f 

type FilePath =
  Chars

-- /Tip:/ Use @getFiles@ and @printFiles@.
run ::
  Chars
  -> IO ()
run filepath = 
  do
     content <- readFile filepath
     files <- getFiles (lines content)
     printFiles files
 
getFiles ::
  List FilePath
  -> IO (List (FilePath, Chars))
getFiles paths =
  sequenceIO (map getFile paths)

getFile ::
  FilePath
  -> IO (FilePath, Chars)
getFile path =
--  do contents <- readFile path
--     pure (path, contents)
  readFile path >>= \content -> 
  pure (path, content)

printFiles ::
  List (FilePath, Chars)
  -> IO ()
printFiles as =
  do _ <- (sequenceIO . map (uncurry printFile)) as
     pure ()

printFile ::
  FilePath
  -> Chars
  -> IO ()
printFile path contents =
  putStrLn (constructFileContents path contents)

-- |
--
-- prop> x + 0 == x
constructFileContents ::
  FilePath
  -> Chars
  -> Chars
constructFileContents path contents =
  "============ " ++ path ++ "\n" ++ contents

sequenceIO ::
  List (IO a)
  -> IO (List a)
sequenceIO Nil =
  pure Nil
sequenceIO (h:.t) =
  -- h :: IO a
  -- sequence t :: IO (List a)
  -- a :: a
  -- r :: List a
  {-
  h            >>= \a ->
  sequenceIO t >>= \r ->
  pure (a :. r)
-}
  do a <- h
     r <- sequenceIO t
     pure (a :. r)

  -- foldRight (twiceOptional (:.)) (Full Nil)
  -- foldRight (twiceParser (:.)) (valueParser Nil)
  -- foldRight (twiceIO (:.)) (pure Nil)

twiceIO ::
  (a -> b -> c)
  -> IO a
  -> IO b
  -> IO c
twiceIO f x y =
  do aa <- x
     bb <- y
     pure (f aa bb)

{-
lift0/pure/unit/return
                z ->                       f z

lift1/map/fmap/(<$>)
          (y -> z) ->               f y -> f z  

lift2/liftA2/liftM2          
     (x -> y -> z) ->        f x -> f y -> f z

lift3/liftA3/liftM3     
(w -> x -> y -> z) -> f w -> f x -> f y -> f z
-}
