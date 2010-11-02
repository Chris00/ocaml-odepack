(* File: odepack.mli

   Copyright (C) 2010

     Christophe Troestler <Christophe.Troestler@umons.ac.be>
     WWW: http://math.umons.ac.be/an/software/

   This library is free software; you can redistribute it and/or modify
   it under the terms of the GNU Lesser General Public License version 3 or
   later as published by the Free Software Foundation, with the special
   exception on linking described in the file LICENSE.

   This library is distributed in the hope that it will be useful, but
   WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the file
   LICENSE for more details. *)

(** Binding to ODEPACK. *)

open Bigarray

type 'a vec = (float, float64_elt, 'a) Array1.t
(** Representation of vectors (parametrized by their layout). *)

type 'a mat = (float, float64_elt, 'a) Array2.t
(** Representation of matrices (parametrized by their layout). *)

type 'a int_vec = (int, int_elt, 'a) Array1.t
(** Representation of integer vectors (parametrized by their layout). *)

type 'a t
(** A mutable value holding the current state of solving the ODE. *)

(** Types of Jacobian matrices. *)
type 'a jacobian =
| Auto_full (** Internally generated (difference quotient) full Jacobian *)
| Auto_band of int * int (** Internally generated (difference
                             quotient) band Jacobian.  The arguments
                             [(l,u)] are the *)
| Full of (float -> 'a vec -> 'a mat -> unit)
| Band of (float -> 'a vec -> int -> 'a mat -> unit)
(** [Band f] [df t y d m]
    [m <- ∂f/∂y(t, y)] where [m] is a band matrix
    [d] being the index of the line of [m] corresponding to the diagonal
 *)

val lsoda : ?rtol:float -> ?rtol_vec:'a vec -> ?atol:float -> ?atol_vec:'a vec ->
  ?jac:'a jacobian ->
  (float -> 'a vec -> 'a vec -> unit) -> float -> 'a vec -> float -> 'a t
(** [lsoda f t0 y0 t] solves the ODE dy/dt = F(t,y) with initial
    condition y([t0]) = [y0].  The execution of [f t y y'] must
    compute the value of the F([t], [y]) and store it in [y'].  The
    vector [y0] is MODIFIED to contain the value of the solution at
    time [t].

    @param rtol  relative error tolerance parameter.
    @param rtol_vec  relative error tolerance vector.
    @param atol  absolute error tolerance parameter.
    @param atol_vec  absolute error tolerance vector.

    @param jac is an optional Jabobian matrix.  If the problem is
    expected to be stiff much of the time, you are encouraged to supply
    [jac], for the sake of efficiency.  Default: [Auto_full].
*)

val vec : 'a t -> 'a vec
(** [vec ode] returns the current value of the solution vector.  *)

val t : 'a t -> float
(** [t ode] returns the current time at which the solution vector was
    computed. *)

val advance : 'a t -> float -> unit
