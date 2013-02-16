(* setup.ml generated for the first time by OASIS v0.2.0 *)


(* OASIS_START *)
(* DO NOT EDIT (digest: 7f47a529f70709161149c201ccd90f0b) *)
#use "topfind";;
#require "oasis.dynrun";;
open OASISDynRun;;
(* OASIS_STOP *)

open Printf

(* Naive substring detection *)
let rec is_substring_pos j p lenp i s lens =
  if j >= lenp then true
  else if i >= lens then false
  else if p.[j] = s.[i] then is_substring_pos (j+1) p lenp (i+1) s lens
  else false
let rec is_substring_loop p lenp i s lens =
  if is_substring_pos 0 p lenp i s lens then true
  else if i >= lens then false
  else is_substring_loop p lenp (i+1) s lens
let is_substring p s =
  is_substring_loop p (String.length p) 0 s (String.length s)

let fortran_compilers = ["gfortran"; "g95"; "g77"]

let fortran_lib() =
  try
    let fortran = BaseCheck.prog_best "fortran" fortran_compilers () in
    if is_substring "gfortran" fortran then "gfortran"
    else ""
  with _ ->
    printf "Please install one of these fortran compilers: %s.\nIf you use \
      a different compiler, send its name to the author (see _oasis file).\n%!"
      (String.concat ", " fortran_compilers);
    exit 1

let _ = BaseEnv.var_define "fortran_library" fortran_lib


let () = setup ()
