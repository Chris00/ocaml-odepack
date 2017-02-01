(* OASIS_START *)
(* DO NOT EDIT (digest: a426e2d026defb34183b787d31fbdcff) *)
(******************************************************************************)
(* OASIS: architecture for building OCaml libraries and applications          *)
(*                                                                            *)
(* Copyright (C) 2011-2016, Sylvain Le Gall                                   *)
(* Copyright (C) 2008-2011, OCamlCore SARL                                    *)
(*                                                                            *)
(* This library is free software; you can redistribute it and/or modify it    *)
(* under the terms of the GNU Lesser General Public License as published by   *)
(* the Free Software Foundation; either version 2.1 of the License, or (at    *)
(* your option) any later version, with the OCaml static compilation          *)
(* exception.                                                                 *)
(*                                                                            *)
(* This library is distributed in the hope that it will be useful, but        *)
(* WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY *)
(* or FITNESS FOR A PARTICULAR PURPOSE. See the file COPYING for more         *)
(* details.                                                                   *)
(*                                                                            *)
(* You should have received a copy of the GNU Lesser General Public License   *)
(* along with this library; if not, write to the Free Software Foundation,    *)
(* Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301 USA              *)
(******************************************************************************)

let () =
  try
    Topdirs.dir_directory (Sys.getenv "OCAML_TOPLEVEL_PATH")
  with Not_found -> ()
;;
#use "topfind";;
#require "oasis.dynrun";;
open OASISDynRun;;

let setup_t = BaseCompat.Compat_0_4.adapt_setup_t setup_t
open BaseCompat.Compat_0_4
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

let fortran_compilers = ["gfortran"; "g95"; "g77"; "f77"]

let fortran_lib() =
  try
    let fortran = BaseCheck.prog_best "fortran" fortran_compilers () in
    if is_substring "gfortran" fortran then "gfortran"
    else if is_substring "g77" fortran then "g2c"
    else if is_substring "f77" fortran then "f2c"
    else ""
  with _ ->
    printf "Please install one of these fortran compilers: %s.\nIf you use \
      a different compiler, send its name to the author (see _oasis file).\n%!"
      (String.concat ", " fortran_compilers);
    exit 1

(* On OSX, the OCaml compiler is Clang and must be passed the path of
   "gfortran". *)
let fortran_library_path () =
  try
    let p = OASISExec.run_read_one_line ~ctxt:!BaseContext.default
              "gfortran" ["--print-file-name"; "libgfortran.dylib"] in
    Filename.dirname p
  with Failure _ -> ""

let _ = BaseEnv.var_define "fortran_library_path" fortran_library_path

let _ = BaseEnv.var_define "fortran_library" fortran_lib

let () = setup ()
