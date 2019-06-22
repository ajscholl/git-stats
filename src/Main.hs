module Main where

import Control.Monad

import Data.Char
import Data.List

import Data.Map (Map)
import qualified Data.Map as Map

import Text.Printf

import System.Directory
import System.FilePath
import System.Process

data Block = Block String [Change] deriving Show
data Change = Change !Int !Int FilePath deriving Show
type AuthorMap = Map String String

parseLog :: [String] -> [Block]
parseLog [] = []
parseLog (('A':':':author):xs) = case parseChunks xs of
    (changes, ys) -> Block author changes : parseLog ys
parseLog (_:xs) = parseLog xs

parseChunks :: [String] -> ([Change], [String])
parseChunks [] = ([], [])
parseChunks (x:xs) = case parseLine x of
    Nothing     -> ([], x:xs)
    Just change -> case parseChunks xs of
        (changes, ys) -> (change : changes, ys)

parseLine :: String -> Maybe Change
parseLine "" = Nothing
parseLine (c:cs) = do
    guard $ isDigit c
    let (ins, ds) = span isDigit $ c : cs
        (del, es) = span isDigit $ dropWhile isSpace ds
        file = dropWhile isSpace es
    guard $ not $ null ins
    guard $ not $ null del
    guard $ not $ null file
    pure $! Change (read ins) (read del) file

unifyAuthors :: AuthorMap -> [Block] -> [Block]
unifyAuthors am = map $ \ (Block author changes) -> case Map.lookup author am of
    Nothing -> Block author changes
    Just na -> Block na changes

accumBlocks :: [Block] -> Map String (Int, Int)
accumBlocks = foldr sumBlock mempty
    where
        sumBlock (Block author changes) acc = foldr (\ (Change ins del _) -> accum author ins del) acc changes
        accum author ins del = Map.alter (Just . accum' ins del) author
        accum' ins del Nothing = (ins, del)
        accum' ins del (Just (ins', del')) = let
                ins'' = ins + ins'
                del'' = del + del'
            in ins'' `seq` del'' `seq` (ins'', del'')

gitLog :: IO String
gitLog = do
    let cmd = shell "git log --pretty=format:\"A:%an\" --numstat --no-merges"
    readCreateProcess cmd ""

readAuthorMap :: IO AuthorMap
readAuthorMap = do
    homeDir <- getHomeDirectory
    let file = homeDir </> ".git-authors"
    exists <- doesFileExist file
    if exists
    then foldMap parseMapping . lines <$> readFile file
    else pure mempty
    where
        parseMapping s = case break ('=' ==) s of
            (a, b) -> Map.singleton (trim a) (trim $ drop 1 b)
        trim = reverse . dropWhile isSpace . reverse . dropWhile isSpace

main :: IO ()
main = do
    am <- readAuthorMap
    lg <- gitLog
    let showInt n
            | n < 0     = '-' : showInt (-n)
            | n >= 1000 = showInt (n `quot` 1000) ++ ',' : printf "%03d" (n `mod` 1000)
            | otherwise = show n
    printf "Git scores (in LOC):% 26s% 15s% 15s\n" "Inserted" "Deleted" "Difference"
    forM_ (sortOn (\ (_, (ins, del)) -> del - ins) $ Map.toList $ accumBlocks $ unifyAuthors am $ parseLog $ lines lg) $ \ (author, (ins, del)) -> printf
        "%s % 14s % 14s % 14s\n" (take 30 author ++ ":" ++ take (30 - length author) (replicate 30 ' ')) ('+' : showInt ins) ('-' : showInt del) $ case ins - del of
            n | n < 0     -> showInt n
              | otherwise -> '+' : showInt n
