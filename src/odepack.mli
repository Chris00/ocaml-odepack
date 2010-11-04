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

(** Binding to ODEPACK.

    @author Christophe Troestler (Christophe.Troestler\@umons.ac.be)
    @version 0.3
*)

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
                             quotient) band Jacobian.  It takes
                             [(l,u)] where [l] (resp. [u]) is the
                             number of lines below (resp. above) the
                             diagonal (excluded). *)
| Full of (float -> 'a vec -> fortran_layout mat -> unit)
(** [Full df] means that a function [df] is provided to compute the
    full Jacobian matrix (∂f_i/∂y_j) of the vector field f(t,y).
    [df t y jac] must store ∂f_i/∂y_j([t],[y]) into [jac.{i,j}]. *)
| Band of int * int * (float -> 'a vec -> int -> fortran_layout mat -> unit)
(** [Band(l, u, df)] means that a function [df] is provided to compute
    the banded Jacobian matrix with [l] (resp. [u]) diagonals below
    (resp. above) the main one (not counted).  [df t y d jac] must
    store ∂f_i/∂y_j([t],[y]) into [jac.{i-j+d, j}].  [d] is the row of
    [jac] corresponding to the main diagonal of the Jacobian matrix.  *)

val lsoda : ?rtol:float -> ?rtol_vec:'a vec -> ?atol:float -> ?atol_vec:'a vec ->
  ?jac:'a jacobian ->
  (float -> 'a vec -> 'a vec -> unit) -> 'a vec -> float -> float -> 'a t
(** [lsoda f y0 t0 t] solves the ODE dy/dt = F(t,y) with initial
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
(** [advance ode t] modifies [ode] so that an approximation of the
    value of the solution at times [t] is computed. *)

val sol : 'a t -> float -> 'a vec
(** [sol ode t] modifies [ode] so that it holds an approximation of
    the solution at [t] and returns this approximation. *)
