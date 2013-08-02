(* setup.ml generated for the first time by OASIS v0.2.0 *)

let () =
  try Topdirs.dir_directory (Sys.getenv "OCAML_TOPLEVEL_PATH")
  with Not_found -> ();;

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

let _ = BaseEnv.var_define "fortran_library" fortran_lib

(* Download ODEPACK FORTRAN code. *)
let odepack_url = "http://netlib.sandia.gov/odepack/"
let odepack_files = ["opkda1.f"; "opkda2.f"; "opkdmain.f"]
let odepack_dir = "src/fortran"

let download_fortran_odepack() =
  (try OASISFileUtil.mkdir ~ctxt:!OASISContext.default "src/fortran"
   with _ -> ());
  let d = Sys.getcwd() in
  Sys.chdir odepack_dir;
  let download =
    try
      let curl = BaseCheck.prog "curl" () in
      fun url -> OASISExec.run ~ctxt:!OASISContext.default
                            curl ["--insecure"; "--retry"; "2";
                                  "--retry-delay"; "2"; "--location";
                                  "--remote-name"; url ]
    with PropList.Not_set _ ->
      (* Curl not found, try wget. *)
      let wget = BaseCheck.prog "wget" () in
      fun url -> OASISExec.run ~ctxt:!OASISContext.default
                            wget ["--no-check-certificate"; "-t"; "2";
                                  url ]
  in
  List.iter (fun fn ->
             if not(Sys.file_exists fn) then
               download (odepack_url ^ fn)
            ) odepack_files;
  Sys.chdir d

(* Only perform the download at configure time. *)
let _ = BaseEnv.var_define "download_fortran_odepack"
                           (fun () -> download_fortran_odepack(); "DONE")


let () = setup ()
