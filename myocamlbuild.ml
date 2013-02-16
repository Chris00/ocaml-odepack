(* OASIS_START *)
(* OASIS_STOP *)

let env = BaseEnvLight.load() (* setup.data *)
let fortran = BaseEnvLight.var_get "fortran" env
let fortran_lib = BaseEnvLight.var_get "fortran_library" env

let () =
  dispatch
    (MyOCamlbuildBase.dispatch_combine [
         dispatch_default;
         begin function
           | After_rules ->
             let odepack = [ "src" / "fortran" / "opkda1.o";
                             "src" / "fortran" / "opkda2.o";
                             "src" / "fortran" / "opkdmain.o"] in
             dep ["c"; "compile"] ("src" / "f2c.h" :: odepack);

             flag ["ocamlmklib"; "c"] (S(List.map (fun p -> P p) odepack));


             rule "Fortran to object" ~prod:"%.o" ~dep:"%.f"
                  (fun env _build ->
                   let f = env "%.f" and o = env "%.o" in
                   let tags = tags_of_pathname f ++ "compile"++"fortran" in

                   let cmd = Cmd(S[A fortran; A"-c"; A"-o"; P o; A"-fPIC";
                                   A"-O3"; A"-std=legacy"; T tags; P f ]) in
                   Seq[cmd]
                  );
             if fortran_lib <> "" then (
               let flib = (S[A"-cclib"; A("-l" ^ fortran_lib)]) in
               flag ["ocamlmklib"]  flib;
               flag ["extension:cma"]  flib;
               flag ["extension:cmxa"] flib;
             );

           | _ -> ()
         end
    ])
