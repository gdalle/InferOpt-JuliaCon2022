### A Pluto.jl notebook ###
# v0.19.11

#> [frontmatter]
#> title = "InferOpt - JuliaCon22"
#> date = "2021-07-09"
#> description = "Presentation of the InferOpt.jl package at JuliaCon 2022"

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╠═╡ show_logs = false
begin
	using Distributions
	using Flux
	using ForwardDiff
	using GLPK
	using Graphs
	using GridGraphs
	using InferOpt
	using Images
	using JuMP
	using LaTeXStrings
	using LinearAlgebra
	using Plots
	using PlutoUI
	using ProgressLogging
	using Random
	using SparseArrays
	using Statistics
	using TikzPictures
	Random.seed!(63)
end;

# ╔═╡ 1dbd6f48-d07c-428d-9dad-3bbbf80a73c4
md"""
**Utilities (hidden)**
"""

# ╔═╡ 0cd10bf9-c31e-4f86-833a-f6f64b951015
md"""
Imports
"""

# ╔═╡ 6cf9db2d-f16d-4e4e-a1e4-915d37a2705f
md"""
TOC
"""

# ╔═╡ 8aa02b43-9c28-4d7e-8eac-551b1e8a4e76
md"""
Figures
"""

# ╔═╡ 5e9486a3-5518-44ad-a9f2-d5371092e46f
fig = TikzPicture(
	L"""
	\tikzset{dummy/.style={fill=green!10, shape=rectangle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
	\tikzset{task/.style={fill=orange!10, shape=circle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
	\tikzset{selected/.style={->, >=stealth, line width=2}}
	\tikzset{redpath/.style={selected, color=red}}
	\tikzset{bluepath/.style={selected, color=blue}}
	\tikzset{purplepath/.style={selected, color=purple}}
	\tikzset{nopath/.style={thick, ->, dashed, line width=2}}
	tikzset{EdgeStyle/.style = {
	  thick,
	  text = black,
	  ->,>=stealth'
	}}
	\node[dummy] (o) at (0,0) {$o$};
	\node[task] (v1) at (5,7.5) {$t_1$};
	\node[task] (v2) at (5,0) {$t_2$};
	\node[task] (v3) at (10,2.5) {$t_3$};
	\node[task] (v4) at (15,10) {$t_4$};
	\node[task] (v5) at (15,5) {$t_5$};
	\node[task] (v6) at (15,0) {$t_6$};
	\node[task] (v7) at (20,7.5) {$t_7$};
	\node[task] (v8) at (20,2.5) {$t_8$};
	\node[dummy] (d) at (25,0) {$d$};
	\draw[redpath] (o) edge (v1);
	\draw[redpath] (v1) edge (v4);
	\draw[redpath] (v4) edge (v7);
	\draw[redpath] (v7) edge (d);
	\draw[bluepath] (o) edge (v3);
	\draw[bluepath] (v3) edge (v5);
	\draw[bluepath] (v5) edge (v8);
	\draw[bluepath] (v8) edge (d);
	\draw[purplepath] (o) edge (v2);
	\draw[purplepath] (v2) edge (v6);
	\draw[purplepath] (v6) edge (d);
	\draw[nopath] (v1) edge (v3);
	\draw[nopath] (v2) edge (v3);
	\draw[nopath] (v3) edge (v4);
	\draw[nopath] (v3) edge (v6);
	\draw[nopath] (v5) edge (v7);
	\draw[nopath] (v6) edge (v8);
	\node[] (time1) at (-1, -2) {};
	\node[] (time2) at (26, -2) {};
	\draw[line width=1.5, ->, >=stealth] (time1) edge node[font=\Huge, below, pos=0.95]{time} (time2);
	""",
	options="scale=1"
);

# ╔═╡ e716f94c-1f4a-4616-bc65-c1e48723bfe3
fig2 = TikzPicture(
	L"""
	\tikzset{node/.style={fill=red!10, shape=rectangle, draw=black, minimum width=100, minimum height=40, font=\LARGE, line width=1.5}}
	\node[node] (t) at (0, 0) {$t$};
	\node[node] (u) at (7, 0) {$u$};
	\node[] (time1) at (-2, -1) {};
	\node[] (time2) at (9, -1) {};
	\draw[<->, line width=1.5] (t) edge node[below]{slack $\Delta_{u,t}$} (u);
	\draw[->, line width=1.5] (time1) edge node[below, pos=0.95]{time} (time2);
	""",
	options="scale=1"
);

# ╔═╡ 954276ad-e5b9-43c2-a969-30410829e778
md"""
Arrow fix
"""

# ╔═╡ a8a40434-4b36-411c-b364-a1056b8295a5
html"""
<script>
    const calculate_slide_positions = (/** @type {Event} */ e) => {
        const notebook_node = /** @type {HTMLElement?} */ (e.target)?.closest("pluto-editor")?.querySelector("pluto-notebook")
		console.log(e.target)
        if (!notebook_node) return []
        const height = window.innerHeight
        const headers = Array.from(notebook_node.querySelectorAll("pluto-output h1, pluto-output h2"))
        const pos = headers.map((el) => el.getBoundingClientRect())
        const edges = pos.map((rect) => rect.top + window.pageYOffset)
        edges.push(notebook_node.getBoundingClientRect().bottom + window.pageYOffset)
        const scrollPositions = headers.map((el, i) => {
            if (el.tagName == "H1") {
                // center vertically
                const slideHeight = edges[i + 1] - edges[i] - height
                return edges[i] - Math.max(0, (height - slideHeight) / 2)
            } else {
                // align to top
                return edges[i] - 20
            }
        })
        return scrollPositions
    }
    const go_previous_slide = (/** @type {Event} */ e) => {
        const positions = calculate_slide_positions(e)
        const pos = positions.reverse().find((y) => y < window.pageYOffset - 10)
        if (pos) window.scrollTo(window.pageXOffset, pos)
    }
    const go_next_slide = (/** @type {Event} */ e) => {
        const positions = calculate_slide_positions(e)
        const pos = positions.find((y) => y - 10 > window.pageYOffset)
        if (pos) window.scrollTo(window.pageXOffset, pos)
    }
	const left_button = document.querySelector(".changeslide.prev")
	const right_button = document.querySelector(".changeslide.next")
	left_button.addEventListener("click", go_previous_slide)
	right_button.addEventListener("click", go_next_slide)
</script>
"""

# ╔═╡ dc635c3b-3bd5-4542-9970-69acb3bfc207
md"""
Two columns
"""

# ╔═╡ d6c80374-a253-4943-98fb-977c6deefa1d
begin
	struct TwoColumn{L, R}
	    left::L
	    right::R
		leftfrac::Int
		rightfrac::Int
	end
	
	function Base.show(io, mime::MIME"text/html", tc::TwoColumn)
		(; left, right, leftfrac, rightfrac) = tc
	    write(io, """<div style="display: flex;"><div style="flex: $(leftfrac)%;">""")
	    show(io, mime, left)
	    write(io, """</div><div style="flex: $(rightfrac)%;">""")
	    show(io, mime, right)
	    write(io, """</div></div>""")
	end
end

# ╔═╡ d487df8f-dc41-4f00-be4e-9d5c4b97e7a4
md"""
Learning
"""

# ╔═╡ ee2daf54-7a9e-4e31-a015-610479671424
dropfirstdim(z::AbstractArray) = dropdims(z; dims=1)

# ╔═╡ 3f003028-ece9-41e6-98c0-3c03652ef3af
function normalized_hamming_distance(x::AbstractArray{<:Real}, y::AbstractArray{<:Real})
    return mean(x[i] != y[i] for i in eachindex(x))
end

# ╔═╡ 25bd7d39-cb39-4bab-879f-54ed98169b34
md"""
Polytope animation
"""

# ╔═╡ eab0af69-82ba-43f1-bc40-7fddfe7b2e12
md"""
# InferOpt.jl: combinatorial optimization in machine learning pipelines

**[Guillaume Dalle](https://gdalle.github.io/), [Léo Baty](https://batyleo.github.io/), [Louis Bouvier](https://louisbouvier.github.io/) & [Axel Parmentier](https://cermics.enpc.fr/~parmenta/)**

CERMICS, École des Ponts

Notebook access: [gdalle.github.io/inferopt-juliacon2022/](gdalle.github.io/inferopt-juliacon2022/)
"""

# ╔═╡ 3ff8833b-e8d8-4621-b062-d3065de91ba6
begin
	ptetes = load("./images/tetes.png")
end

# ╔═╡ c820e809-5d03-4073-8326-1fe782decb44
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 5b6d013f-2d8c-4919-8fe4-4af5219c3634
md"""
# 1. What is it for ?
"""

# ╔═╡ 5cb8738a-7c85-4c88-984e-5a86fcd7acd5
md"""

**Points of view**: 
- Enrich learning pipelines with combinatorial algorithms.
- Enhance combinatorial algorithms with learning pipelines.

```math
\xrightarrow[\text{instance}]{\text{Initial}}
\fbox{ML predictor}
\xrightarrow[\text{instance}]{\text{Encoded}}
\fbox{CO algorithm}
\xrightarrow[\text{solution}]{\text{Candidate}}
\text{Loss}
```

**Challenge:** Differentiating through CO algorithms.

**Two learning settings:**
- Learning by imitation.
- Learning by experience.
"""

# ╔═╡ 04e00283-05c2-4b1b-8c44-54fb1dddb124
md"""
## Many possible applications

- Shortest paths on Warcraft maps $\impliedby$ **today**.
- Stochastic Vehicle Scheduling $\impliedby$ **today**.
- Two-stage Minimum Spanning Tree $\impliedby$ see satellite packages.
- Single-machine scheduling $\impliedby$ see satellite packages.
"""

# ╔═╡ ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
md"""
## Shortest paths on Warcraft maps

Source: [Vlastelica et al. (2020)](https://openreview.net/forum?id=BkevoJSYPB)

**Dataset**: Each point contains

 - an image of a map, where each terrain type has a specific cost
 - a shortest path from the top-left to the bottom-right corners.

**Goal**: Learn to recognize terrain types, in order to find shortest paths from new map images.
"""

# ╔═╡ ad1a47b9-d9d3-4f39-ad8e-7749c651da12
begin
	mapterrain = plot(load("./images/Warcraft/map.png"), title = "Terrain map")
	labelpath = plot(load("./images/Warcraft/path.png"), title = "Label shortest path")
	plot(mapterrain, labelpath, layout = (1,2), ticks = nothing, border = nothing, size = (800, 400))
end

# ╔═╡ f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
md"""
## ML-CO pipeline
"""

# ╔═╡ 4c661db2-312a-4e03-8f66-df2bb68ad9a7
begin
	warcraftpipeline = load("./images/Warcraft/warcraft_pipeline.png")
end

# ╔═╡ 52ca4280-f092-4941-aed5-e3fc25b3149a
md"""
## Test set prediction (1)

We can compare the predicted costs $\theta = \varphi_w(x)$ and the true costs on samples from the test set.
"""

# ╔═╡ 88ba9bb1-02b3-4f32-bf6c-be8f99626f13
begin 
	true_costs = plot(load("./images/Warcraft/costs.png"), title = "True costs")
	computed_costs = plot(load("./images/Warcraft/computed_costs.png"), title = "Computed costs")
	plot(mapterrain, true_costs, computed_costs, layout = (1,3), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ 9dee8b4a-451c-4714-8257-9a47b2133002
md"""
## Test set prediction (2)
"""

# ╔═╡ ea2faddf-38b2-46ab-9a53-2057ade1f198
begin 
	computed_path = plot(load("./images/Warcraft/computed_path.png"), title = "Computed shortest path")
	plot(mapterrain, labelpath, computed_path, layout = (1,3), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ 5f023b91-b0ae-4e91-94fb-f56312c8135f
md"""
## Stochastic Vehicle Scheduling
"""

# ╔═╡ c06b600f-3a79-416e-b2d8-3d85c571d2c8
fig

# ╔═╡ 155ee558-8b6f-446b-adbe-41355e9745c0
md"""
- Set of **delivery tasks** ``t\in T``.
- Predefined time and duration for each task.
- **Decision variables**: schedule of vehicle tours.
- **Constraint**: all tasks must be fulfilled by exactly one vehicle.
"""

# ╔═╡ 0f9a59ac-4a82-4bbd-b662-344491304c53
md"""
## Why "stochastic"?

- Once vehicle tours are set, random delays occur:
  - Set of scenarios ``S``
  - Intrinsic delay of task ``t``: ``\varepsilon_t^s``
  - Slack tasks between tasks ``u`` and ``t``: ``\Delta_{u, t}^s``
  - Delay propagation equation: ``d_t^s = \varepsilon_t^s + \max(d_u^s - \Delta_{u, t}^s, 0)``

- **Objective**: minimize vehicle costs + average delay cost
"""

# ╔═╡ 3dfd513a-d8c0-4e04-aa57-02ee1a63367e
fig2

# ╔═╡ bf2619d5-8f84-4340-9e6f-8343d687fc03
md"""
## MILP formulation
"""

# ╔═╡ 97a8e5d2-85e3-428c-99f0-5348324ea5c6
fig

# ╔═╡ 3e268142-8c00-423f-ab45-abb37e904bb2
md"""
We have the following hard problem: 

```math
(H)\left\{
\begin{aligned}
\min & \frac{1}{|S|} \sum_{s \in S} \sum_{p \in \mathcal{P}}c_p^s y_p &\\

\text{s.t.} & \sum_{p \ni v} y_p = 1 & \forall v \in V \backslash\{o, d\} \quad(\lambda_v \in \mathbb{R})\\

& y_p \in \{0,1\} & \forall p \in \mathcal{P}
\end{aligned}
\right.
```

"""

# ╔═╡ 296fc611-5d26-44c4-8df8-209401a8582a
md"""
## Approximate the hard problem

... with an easier one
```math
(E)\left\{
\begin{aligned}
\min_y &\quad \sum_{a\in\ A}\theta_a y_a\\
\text{s.t.} & \sum_{a\in\delta^-(t)}y_a = \sum_{a\in\delta^+(t)}y_a,\quad & \forall t\in T\\
& \sum_{a\in\delta^+(t)}y_a = 1, & \forall t\in T
\end{aligned}
\right.
```

``\implies`` Vehicle Scheduling Problem that can be solved with flow algorithms, or linear programming

Goal: for an instance ``x`` of ``(H)``, find ``\theta(x)`` such that the solution ``\hat y(\theta)`` of ``(E)`` is a good solution of ``(H)``
"""

# ╔═╡ 7c7a76b5-ff7e-4731-96f4-49100d59e03a
md"""
## ML-CO pipeline

```math
\xrightarrow[x \text{ of } (H)]{\text{Instance}}
\fbox{Features $\xi(a, x)$}
\xrightarrow[]{\xi\in \mathbb{R}^{k\times d(x)}}
\fbox{GLM $\xi \mapsto w^\top \xi$}
\xrightarrow[\theta \in \mathbb{R}^{d(x)}]{\text{Cost vector}}
\fbox{Optimizer}
\xrightarrow[y \in \mathcal{Y}(x)]{\text{Solution}}
```

Machine learning predictor:
- ``\theta_a = w^T \xi(a, x)``
- learnable weights ``w``
"""

# ╔═╡ c9cef05b-944b-4595-863d-a0312973d5a3
TikzPicture(L"""
\tikzset{dummy/.style={fill=green!10, shape=rectangle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
\tikzset{task/.style={fill=orange!10, shape=circle, draw=black, minimum size=60, font=\Huge, line width=1.5}}
\tikzset{selected/.style={->, >=stealth, line width=2}}
\tikzset{redpath/.style={selected, color=red}}
\tikzset{bluepath/.style={selected, color=blue}}
\tikzset{purplepath/.style={selected, color=purple}}
\tikzset{nopath/.style={thick, ->, dashed, line width=2}}
tikzset{EdgeStyle/.style = {
  thick,
  text = black,
  ->,>=stealth'
}}
\node[dummy] (o) at (0,0) {$o$};
\node[task] (v1) at (5,7.5) {$t_1$};
\node[task] (v2) at (5,0) {$t_2$};
\node[task] (v3) at (10,2.5) {$t_3$};
\node[task] (v4) at (15,10) {$t_4$};
\node[task] (v5) at (15,5) {$t_5$};
\node[task] (v6) at (15,0) {$t_6$};
\node[task] (v7) at (20,7.5) {$t_7$};
\node[task] (v8) at (20,2.5) {$t_8$};
\node[dummy] (d) at (25,0) {$d$};
\draw[nopath] (o) edge (v1);
\draw[nopath] (v1) edge (v4);
\draw[nopath] (v4) edge (v7);
\draw[nopath] (v7) edge (d);
\draw[nopath] (o) edge (v3);
\draw[nopath] (v3) edge (v5);
\draw[nopath] (v5) edge (v8);
\draw[nopath] (v8) edge (d);
\draw[nopath] (o) edge (v2);
\draw[nopath, color=red] (v2) edge node[font=\LARGE, color=red, above]{$\theta_{2, 6} = w^\top \xi((2, 6), x)$} (v6);
\draw[nopath] (v6) edge (d);
\draw[nopath] (v1) edge (v3);
\draw[nopath] (v2) edge (v3);
\draw[nopath] (v3) edge (v4);
\draw[nopath] (v3) edge (v6);
\draw[nopath] (v5) edge (v7);
\draw[nopath] (v6) edge (v8);
\node[] (time1) at (-1, -2) {};
\node[] (time2) at (26, -2) {};
\draw[line width=1.5, ->, >=stealth] (time1) edge node[font=\Huge, below, pos=0.95]{time} (time2);
""", options="scale=1")

# ╔═╡ b7477763-33b6-4506-a253-f0700472788d
md"""
## Results: delays propagation
"""

# ╔═╡ cd4f2546-fe46-42db-8197-7278ccd32cbe
begin 
	vspexperience = plot(load("./images/VSP/vsp_experience.png"))
	vspheuristic = plot(load("./images/VSP/vsp_heuristic.png"))
	plot(vspheuristic, vspexperience, layout = (1,2), ticks = nothing, border = nothing, size = (800, 300))
end

# ╔═╡ fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
md"""
# 2. Theoretical background

A brief introduction to structured learning by imitation
"""

# ╔═╡ 1484d096-0beb-44d7-8192-6948f3ccd7ca
md"""
## Smoothing by regularization

```math
\xrightarrow[\text{instance $x$}]{\text{Problem}}
\fbox{NN $\varphi_w$}
\xrightarrow[\text{direction $\theta$}]{\text{Objective}}
\fbox{MILP $\underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$}
\xrightarrow[\text{solution $\widehat{y}$}]{\text{Candidate}}
\fbox{Loss}
```

The function $\theta \mapsto \underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$ is piecewise constant $\implies$ no gradient information.

Given a convex function $\Omega$, the regularized optimizer is defined by:

```math
\hat{y}_\Omega(\theta) = \underset{y \in \mathrm{conv}(\mathcal{Y})}{\mathrm{argmax}} \{\theta^\top y - \Omega(y)\} 
```
"""

# ╔═╡ 33a8bfd4-c5c6-42a0-add7-334e153f1785
md"""
## Regularization
"""

# ╔═╡ 33523f7c-974e-45d1-968b-63c80bca6cdf
md"""
``n =`` $(@bind n Slider(3:10; default=7, show_value=true))
"""

# ╔═╡ 81011ca8-c063-4ee4-8aaa-1a5021504ad0
begin
	Y = [
		[(0.5 + 0.5*rand()) * cospi(2k/n), (0.5 + 0.5*rand()) * sinpi(2k/n)]
		for k in 0:n-1
	]
	vertex_argmax(θ) = Y[argmax(dot(θ, y) for y in Y)]
end;

# ╔═╡ f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
function plot_polytope(α, predictor; title)
	θ = 0.4 .* [cos(α), sin(α)]
	ŷ = vertex_argmax(θ)
	active_set = compute_probability_distribution(predictor, θ)
	A = active_set.atoms
	p = active_set.weights
	ŷΩ = compute_expectation(active_set)
	
	pl = plot(;
		xlim=(-1.1, 1.1),
		ylim=(-1.1, 1.1),
		aspect_ratio=:equal,
		legend=:outerright,
		title=title
	)
	plot!(
		pl,
		vcat(map(first, Y), first(Y[1])),
		vcat(map(last, Y), last(Y[1]));
		fill=(0, :lightgray),
		linestyle=:dash,
		linecolor=:black,
		label=L"\mathrm{conv}(\mathcal{Y})"
	)
	plot!(
		pl,
		[0., θ[1]],
		[0., θ[2]],
		color=:black,
		arrow=true,
		lw=2,
		label=L"\theta"
	)
	scatter!(
		pl,
		[ŷΩ[1]],
		[ŷΩ[2]];
		color=:blue,
		markersize=7,
		label=L"\hat{y}_\Omega(\theta)"
	)
	scatter!(
		pl,
		map(first, A),
		map(last, A);
		markersize=25 .* p .^ 0.5,
		markercolor=:blue,
		markerstrokewidth=0,
		markeralpha=0.4,
		label=nothing
	)
	scatter!(
		pl,
		[ŷ[1]],
		[ŷ[2]];
		color=:red,
		markersize=7,
		markershape=:square,
		label=L"\hat{y}(\theta)"
	)
	pl
end

# ╔═╡ 371a446e-22e3-4607-a6f5-f72d586e4ef6
md"""
``\alpha_{\text{reg}} =`` $(@bind α_reg Slider(0:0.01:2π; default=π))
"""

# ╔═╡ 5cf53359-3e33-4b8e-91ff-4dac4139f315
md"""
	``\varepsilon_{\text{reg}} = `` $(@bind ε_reg Slider(0.01:0.01:1; default=0.01, show_value=true))
	"""

# ╔═╡ 953701fe-c67a-498f-bf83-a50a6b45e38d
begin
	Ω(y) = ε_reg * sum(abs2, y)
	∇Ω(y) = ForwardDiff.gradient(Ω, y)
	regularized = RegularizedGeneric(vertex_argmax, Ω, ∇Ω)
end;

# ╔═╡ 635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
plot_polytope(α_reg, regularized, title="Regularized")

# ╔═╡ 6a322541-4a04-4201-8117-4079e8e5ca2c
md"""
## Fenchel-Young loss
Natural non-negative & convex loss based on regularization:
```math
\boxed{
\mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}) = \Omega^*(\theta) + \Omega(\bar{y}) - \theta^\top \bar{y}
}
```
Given a target solution $\bar{y}$ and a parameter $\theta$, a subgradient is given by:
```math
\widehat{y}_{\Omega}(\theta) - \bar{y} \in \partial_\theta \mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}).
```
The optimization block has meaningful gradients $\implies$ we can backpropagate through the whole pipeline.
"""

# ╔═╡ 86c31ee6-2b45-46c0-99ef-8e8da7c67717
md"""
# 3. Tutorial
"""

# ╔═╡ 53bd8687-a7bb-43b6-b4b1-f487c9fa40af
md"""
## Problem statement

We observe a set of data points:
- a graph ``G``, and features on each node: public transport network
- a shortest path ``P``: itinerary taken by the user

**Objective**: propose relevant paths for the user's future travels

``\implies`` we need to learn the user utility function, which is unknown.
"""

# ╔═╡ 9d28cfad-1ee4-4946-9090-6d06ed985761
md"""
## GridGraphs

- Vertices ``(i, j)``, ``1 \leq i \leq h``, ``1 \leq j \leq w``.
- User can only move right, down or both $\implies$ acyclicity
- The cost of a move is defined as the cost of the arrival vertex
``\implies`` any grid graph is entirely characterized by its cost matrix ``\theta \in \mathbb{R}^{h \times w}``.


See [https://github.com/gdalle/GridGraphs.jl](https://github.com/gdalle/GridGraphs.jl) for more details.
"""

# ╔═╡ b5b1322b-bd82-4f25-b888-7dbefd8fb1e0
h, w = 50, 100;

# ╔═╡ cdffe713-0b1d-45cf-b5d3-ea5b86882986
md"""
## GridGraphs: example
"""

# ╔═╡ 25f0cc4d-f659-44f3-8319-e9a12f8c563a
@bind seed Slider(0:100; default=0)

# ╔═╡ 003ba2de-5aee-4c7d-9af6-2472f714e483
θ = randn(MersenneTwister(seed), h, w);

# ╔═╡ 5ce19f81-2205-4fc2-88dc-ff8e3c50c28e
g = AcyclicGridGraph(θ);

# ╔═╡ 7d2e7333-eded-4168-9364-0b7b63f5acd3
md"""
We can easily compute the shortest path:
"""

# ╔═╡ ef88fae7-1baf-44bc-8405-20acdb9301a0
y = path_to_matrix(g, grid_topological_sort(g, 1, nv(g)));

# ╔═╡ b42d417d-aa67-4988-8c4a-dd105d0353f8
spy(sparse(y))

# ╔═╡ 4633febc-b1ce-43a6-8f3a-854e29c56beb
md"""
## Input data (1)

- We don't know the cost of each vertex.
- We have have access to a set of relevant features.
"""

# ╔═╡ 28437714-35d6-47dd-8609-441fa0a68eda
nb_features, nb_instances = 10, 30;

# ╔═╡ 3614c791-ce6d-41f2-94ae-ed01cf15fbae
md"""
Generate random instances
"""

# ╔═╡ bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
X_train = [randn(nb_features, h, w) for n in 1:nb_instances];

# ╔═╡ a58364b1-debb-4c5d-9f69-6dadb2a57ffa
md"""
Let us assume that the user combines them using a shallow (linear) neural network.
"""

# ╔═╡ 458ab7d6-45dc-43d4-85ed-8ea355aca06d
true_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ da2931b6-4c0b-43cf-882f-328f67f963b2
function path_cost(y; instance)
	θ = true_encoder(instance)
    return return sum(-θ[i] * y[i] for i in eachindex(y))
end;

# ╔═╡ 67081a13-78fd-485a-89c5-0ca04479a76a
md"""
Compute true (unknown) vertex costs
"""

# ╔═╡ 4435ed2f-718b-444e-8c2b-a7c04cde8ad8
θ_train = [true_encoder(x) for x in X_train];

# ╔═╡ 444b6d1f-030e-4c8d-a74d-2ffbf5022649
x = X_train[1];

# ╔═╡ b910aefc-822a-4adc-81e1-b08673729e0c
md"""
## Input data (2)
"""

# ╔═╡ 9f52266e-3ad3-4823-a1ab-dd08294136d6
md"""
The true vertex costs computed from this encoding are then used within longest path computations (shortest path with $-\theta$):

```math
\underset{y \in \mathcal{P}}{\mathrm{argmax}}  ~ \theta^\top y
```
"""

# ╔═╡ 04ca9af8-d29b-4694-af98-fce02036023f
function shortest_path(θ; instance=nothing)
    g = AcyclicGridGraph(-θ)
    path = grid_topological_sort(g, 1, nv(g))
    return path_to_matrix(g, path)
end;

# ╔═╡ 953213c6-4726-400d-adf0-8e36defe1ce4
md"""
Compute optimal paths taken by the user.
"""

# ╔═╡ bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
Y_train = [shortest_path(θ) for θ in θ_train];

# ╔═╡ 0ca87da2-bb36-4c75-bf59-fe2cfe73edd4
md"""
We create a trainable model with the same structure as the true encoder but another set of randomly-initialized weights.
"""

# ╔═╡ f717b0a9-83a3-400b-8093-80fb6561514f
initial_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ bc883d10-c074-4e55-8848-892e7f512556
md"""
## Regularization
"""

# ╔═╡ eaa3491f-3dec-465a-9a8a-96d43cc8c4e8
begin
	set_ε = md"""
	``\varepsilon = `` $(@bind ε Slider(0:0.01:10; default=0.0, show_value=true))
	"""
	set_nb_samples = md"""
	``M = `` $(@bind M Slider(2:50; default=5, show_value=true))
	"""
	TwoColumn(set_ε, set_nb_samples, 50, 50)
end

# ╔═╡ 4107ded4-4e57-4f22-ad50-83735f7a97ff
predictor = PerturbedAdditive(shortest_path; ε=ε, nb_samples=M);

# ╔═╡ be133738-eeea-4db2-90d4-47266bf80a65
spy(predictor(θ_train[1]))

# ╔═╡ 4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
md"""
Instead of choosing just one path, it spreads over several possible paths.

``\implies`` output changes smoothly as ``\theta`` varies.
"""

# ╔═╡ 08b3bac8-e3f3-46eb-b147-683bc540dd81
function normalized_hamming_distance(Y_pred)
	return mean(
		normalized_hamming_distance(y, y_pred)
			for (y, y_pred) in zip(Y_train, Y_pred)
	)
end;

# ╔═╡ 53665dae-662d-4121-b08a-d477fab2578a
begin
	optimal_costs = [path_cost(y; instance=x) for (x, y) in zip(X_train, Y_train)]
	function cost_gap(Y_pred)
		return mean((path_cost(y_pred; instance=x) - c) / abs(c)
			for (x, c, y_pred) in zip(X_train, optimal_costs, Y_pred)
		)
	end
end;

# ╔═╡ 3e384580-500c-4b26-b5ab-d0ec84e1eb40
md"""
## Choosing a loss function

Thanks to this smoothing, we can now train our model with a standard gradient optimizer.
"""

# ╔═╡ d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
regularized_predictor = PerturbedAdditive(shortest_path; ε=1.0, nb_samples=5);

# ╔═╡ 5cb477cd-e20c-4006-90b1-8d43a1fa1ce6
fyloss = FenchelYoungLoss(regularized_predictor);

# ╔═╡ 0671f818-b38e-4ae0-9cc7-fb82244394ac
fyloss(initial_encoder(x), y)

# ╔═╡ 7ebf4038-c827-40de-b1ac-7145a6a297f7
gradient(θ -> fyloss(θ, y), initial_encoder(x))

# ╔═╡ f0220f84-07f7-452f-a975-6f08f27a6d0b
md"""
## 3.1 Training loop
"""

# ╔═╡ e9245c18-1fac-49f5-9f68-a46b8e4c0fc9
md"""
- using Flux here
- compatible with any Julia Machine Learning package
"""

# ╔═╡ 4cc3ae85-028c-4952-9ad8-94063cee74ae
begin
	encoder = deepcopy(initial_encoder)
	opt = ADAM();
	fylosses, fyhamming_distances = Float64[], Float64[]
	@progress for epoch in 1:200
	    l = 0.
	    for (x, y) in zip(X_train, Y_train)
	        grads = gradient(Flux.params(encoder)) do
	            l += fyloss(encoder(x), y)
	        end
	        Flux.update!(opt, Flux.params(encoder), grads)
	    end
	    push!(fylosses, l / length(X_train))
		Y_pred = [shortest_path(encoder(x)) for x in X_train];
		push!(fyhamming_distances, normalized_hamming_distance(Y_pred))
	end;
end;

# ╔═╡ ba00f149-c675-4dfb-97fb-483df8fa761d
md"""
## Results: Loss

Since the Fenchel-Young loss is convex, the training works well:
"""

# ╔═╡ 28eec921-d948-4ace-b0a0-1a35b6f464d7
plot(fylosses, xlabel="Epoch", ylabel="Loss value", title="Fenchel-Young loss evolution", label=nothing)

# ╔═╡ 53521e21-7040-493e-802a-cf75cb4c0f65
@info "Final loss" fylosses[end]

# ╔═╡ d5746b74-f170-45ac-ad93-be3e9d32f3a0
md"""
## Results: normalized hamming distance
"""

# ╔═╡ 1cf291f1-7a8a-4573-891d-ab84162e0895
plot(fyhamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance", title="Hamming distance: predicted vs actual path", label=nothing)

# ╔═╡ 5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
@info "Final hamming distance" fyhamming_distances[end]

# ╔═╡ e42a5c8f-5511-46e1-9495-8fc198fae087
md"""
## 3.2 Training when $\theta$ costs are known

When the user costs $\theta$ are known for our dataset, we can use another loss to leverage this additional information.

``\implies`` Smart "Predict then optimize" setting (see [https://arxiv.org/abs/1710.08005](https://arxiv.org/abs/1710.08005))
"""

# ╔═╡ c1763137-a746-4fc8-b0c7-a4da50105926
spo_loss = SPOPlusLoss(shortest_path);

# ╔═╡ 20ee48a9-7991-43d1-9ade-d1b7f89ebb4e
spo_loss(initial_encoder(x), θ, y)

# ╔═╡ 7ad675e8-bbe7-41a8-ad53-decdb8267097
begin
	encoder2 = deepcopy(initial_encoder)
	spolosses = Float64[]
	spohamming_distances = Float64[]
	@progress for epoch in 1:100
	    l = 0.
	    for (x, θ, y) in zip(X_train, θ_train, Y_train)
	        grads = gradient(Flux.params(encoder2)) do
	            l += spo_loss(encoder2(x), θ, y)
	        end
	        Flux.update!(opt, Flux.params(encoder2), grads)
	    end
	    push!(spolosses, l)
		Y_pred = [shortest_path(encoder2(x)) for x in X_train];
		push!(spohamming_distances, normalized_hamming_distance(Y_pred))
	end;
end;

# ╔═╡ 8010bd8a-5f63-4ee8-8f23-34b59c0297e4
md"""
## Results: Loss
"""

# ╔═╡ 1b17fd8f-008e-4064-a866-332071647796
plot(spolosses, xlabel="Epoch", ylabel="Loss value", title="SPO+ loss evolution", label=nothing)

# ╔═╡ 910f89b9-64dd-480b-b6d7-19f8eb61923d
@info "Final loss" spolosses[end]

# ╔═╡ c6bac43b-dfab-49f8-ae6c-4d33b8b55663
md"""
## Results: normalized hamming distance
"""

# ╔═╡ 5a6759db-ad6c-48ac-aff3-266b76c9b715
plot(spohamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance", title="Hamming distance: predicted vs actual path", label=nothing)

# ╔═╡ 953523a6-fa73-46ca-a59d-11bd818f8a11
@info "Final hamming distance" spohamming_distances[end]

# ╔═╡ ee6a4ba8-1342-448a-999d-aa063e883654
md"""
## 3.3 Training when optimal paths are unknown

If we cannot have access to chosen paths $y$ or user costs $\theta$ for dataset instances $x$, but have a blackbox cost function that can evaluate a given path, we still can do something !

``\implies`` learning by experience setting
"""

# ╔═╡ 28043665-f5fa-4ebc-8388-9a378ce1e894
path_cost

# ╔═╡ 71147b63-5c89-4296-b1a5-e9da2eeeb73e
methods(path_cost)

# ╔═╡ d11d4529-1c0c-4a15-8566-7ef4d86d4c57
predicted_path = shortest_path(initial_encoder(x));

# ╔═╡ 51dcdae9-290b-4c08-be04-071c044ae9e4
path_cost(predicted_path; instance=x)

# ╔═╡ 18dcd447-695f-4c14-b646-5c6b24d961ce
exp_loss = Pushforward(
	PerturbedAdditive(shortest_path; ε=1.0, nb_samples=5), path_cost
)

# ╔═╡ 8b182c60-18f2-413e-b077-eb1c39090fb5
exp_loss(initial_encoder(x); instance=x)

# ╔═╡ 5eeef94f-5bd3-4165-878b-1b4a66ab71a8
begin
	encoder3 = deepcopy(initial_encoder)
	exp_losses, cost_gaps, exp_hamming_distances = Float64[], Float64[], Float64[]
	@progress for epoch in 1:3000
	    l = 0.
	    for x in X_train
	        grads = gradient(Flux.params(encoder3)) do
	            l += exp_loss(encoder3(x); instance=x)
	        end
	        Flux.update!(opt, Flux.params(encoder3), grads)
	    end
	    push!(exp_losses, l);
		Y_pred = [shortest_path(encoder3(x)) for x in X_train];
		push!(cost_gaps, cost_gap(Y_pred))
		push!(exp_hamming_distances, normalized_hamming_distance(Y_pred))
	end
end;

# ╔═╡ 832fa40e-e4ef-42fb-bc25-133d19a5c579
md"""
## Results: loss
"""

# ╔═╡ 2016349b-cfd5-40ef-bfdd-835db6e0f6fe
plot(exp_losses, xlabel="Epoch", ylabel="Loss value", title="Perturbed cost loss", label=nothing)

# ╔═╡ 2eb47163-e8dd-4307-8dff-454cabf81d90
@info "Final loss" exp_losses[end]

# ╔═╡ f1425013-66af-44a9-aada-7101251ef0b9
md"""
## Results: normalized hamming distance
"""

# ╔═╡ c45c5d71-933e-4c1b-bf62-a982ed736ed8
plot(exp_hamming_distances, xlabel="Epoch", ylabel="Hamming distances", title="Hamming distance: predicted vs actual path", label=nothing)

# ╔═╡ 5cc13399-73e9-4717-93cc-fe73f11bccc9
@info "Final hamming distance" exp_hamming_distances[end]

# ╔═╡ f25e58ac-ae39-4c46-9328-5eb5656b37ea
md"""
## Results: cost gap
"""

# ╔═╡ 18657b2f-108e-4f11-ae34-3d889e10e76d
plot(cost_gaps, xlabel="Epoch", ylabel="Gap value", title="Path cost gap: predicted vs actual path", label=nothing)

# ╔═╡ b042bd90-8b5e-4556-b8a9-542e35cdb6de
@info "Final cost gap" cost_gaps[end]

# ╔═╡ 5f5733a5-2bb4-4045-8671-f3dc7b0586fb
md"""
# Conclusion
"""

# ╔═╡ d37939ad-4937-46f9-a5f7-5394a8c38ded
md"""
## For more information

- **Main package:** <https://github.com/axelparmentier/InferOpt.jl>
- **This notebook:** <https://gdalle.github.io/InferOpt-JuliaCon2022/>
- Paper coming soon

More application examples:
- **Single machine scheduling:** <https://github.com/axelparmentier/SingleMachineScheduling.jl>
- **Two stage spanning tree:** <https://github.com/axelparmentier/TwoStageSpanningTree.jl>
- **Shortest paths on Warcraft maps:** <https://github.com/LouisBouvier/WarcraftShortestPaths.jl>
- **Stochastic vehicle scheduling:** <https://github.com/BatyLeo/StochasticVehicleScheduling.jl>
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c"
ForwardDiff = "f6369f11-7733-5829-9624-2563aa707210"
GLPK = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
GridGraphs = "dd2b58c7-5af7-4f17-9e46-57c68ac813fb"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
InferOpt = "4846b161-c94e-4150-8dac-c7ae193c601f"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LaTeXStrings = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ProgressLogging = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
TikzPictures = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"

[compat]
Distributions = "~0.25.68"
Flux = "~0.13.5"
ForwardDiff = "~0.10.32"
GLPK = "~1.0.1"
Graphs = "~1.7.2"
GridGraphs = "~0.7.0"
Images = "~0.25.2"
InferOpt = "~0.3.1"
JuMP = "~1.2.1"
LaTeXStrings = "~1.3.0"
Plots = "~1.31.7"
PlutoUI = "~0.7.39"
ProgressLogging = "~0.1.4"
TikzPictures = "~3.4.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.8.0"
manifest_format = "2.0"
project_hash = "a471207af2d5bcc248156ec07b97970b29eb0020"

[[deps.AMD]]
deps = ["Libdl", "LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "fc66ffc5cff568936649445f58a55b81eaf9592c"
uuid = "14f7f29c-3bd6-536c-9a0b-7339e30b5a3e"
version = "0.4.0"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "69f7020bd72f069c219b5e8c236c1fa90d2cb409"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.2.1"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "195c5505521008abea5aee4f96930717958eac6f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.4.0"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"
version = "1.1.1"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.Arpack]]
deps = ["Arpack_jll", "Libdl", "LinearAlgebra", "Logging"]
git-tree-sha1 = "91ca22c4b8437da89b030f08d71db55a379ce958"
uuid = "7d9fca2a-8960-54d3-9f78-7d1dccf2cb97"
version = "0.5.3"

[[deps.Arpack_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "OpenBLAS_jll", "Pkg"]
git-tree-sha1 = "5ba6c757e8feccf03a1554dfaf3e26b3cfc7fd5e"
uuid = "68821587-b530-5797-8361-c406ea357684"
version = "3.5.1+1"

[[deps.ArrayInterface]]
deps = ["ArrayInterfaceCore", "Compat", "IfElse", "LinearAlgebra", "Static"]
git-tree-sha1 = "0582b5976fc76523f77056e888e454f0f7732596"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "6.0.22"

[[deps.ArrayInterfaceCore]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "40debc9f72d0511e12d817c7ca06a721b6423ba3"
uuid = "30b0a656-2188-435a-8636-2ec0e6a096e2"
version = "0.1.17"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.AxisAlgorithms]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "WoodburyMatrices"]
git-tree-sha1 = "66771c8d21c8ff5e3a93379480a2307ac36863f7"
uuid = "13072b0f-2c55-5437-9ae7-d433b7a33950"
version = "1.0.1"

[[deps.AxisArrays]]
deps = ["Dates", "IntervalSets", "IterTools", "RangeArrays"]
git-tree-sha1 = "1dd4d9f5beebac0c03446918741b1a03dc5e5788"
uuid = "39de3d68-74b9-583c-8d2d-e117c070f3a9"
version = "0.4.6"

[[deps.BFloat16s]]
deps = ["LinearAlgebra", "Printf", "Random", "Test"]
git-tree-sha1 = "a598ecb0d717092b5539dbbe890c98bac842b072"
uuid = "ab4f0b2a-ad5b-11e8-123f-65d77653426b"
version = "0.2.0"

[[deps.Base64]]
uuid = "2a0f44e3-6c83-55bd-87e4-b1978d98bd5f"

[[deps.BenchmarkTools]]
deps = ["JSON", "Logging", "Printf", "Profile", "Statistics", "UUIDs"]
git-tree-sha1 = "4c10eee4af024676200bc7752e536f858c6b8f93"
uuid = "6e4b80f9-dd63-53aa-95a3-0cdb28fa8baf"
version = "1.3.1"

[[deps.Bzip2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "19a35467a82e236ff51bc17a3a44b69ef35185a2"
uuid = "6e34b625-4abd-537c-b88f-471c36dfa7a0"
version = "1.0.8+0"

[[deps.CEnum]]
git-tree-sha1 = "eb4cb44a499229b3b8426dcfb5dd85333951ff90"
uuid = "fa961155-64e5-5f13-b03f-caf6b980ea82"
version = "0.4.2"

[[deps.CUDA]]
deps = ["AbstractFFTs", "Adapt", "BFloat16s", "CEnum", "CompilerSupportLibraries_jll", "ExprTools", "GPUArrays", "GPUCompiler", "LLVM", "LazyArtifacts", "Libdl", "LinearAlgebra", "Logging", "Printf", "Random", "Random123", "RandomNumbers", "Reexport", "Requires", "SparseArrays", "SpecialFunctions", "TimerOutputs"]
git-tree-sha1 = "49549e2c28ffb9cc77b3689dc10e46e6271e9452"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "3.12.0"

[[deps.Cairo_jll]]
deps = ["Artifacts", "Bzip2_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "JLLWrappers", "LZO_jll", "Libdl", "Pixman_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "4b859a208b2397a7a623a03449e4636bdb17bcf2"
uuid = "83423d85-b0ee-5818-9007-b63ccbeb887a"
version = "1.16.1+1"

[[deps.Calculus]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f641eb0a4f00c343bbc32346e1217b86f3ce9dad"
uuid = "49dc2e85-a5d0-5ad3-a950-438e2897f1b9"
version = "0.5.1"

[[deps.CatIndices]]
deps = ["CustomUnitRanges", "OffsetArrays"]
git-tree-sha1 = "a0f80a09780eed9b1d106a1bf62041c2efc995bc"
uuid = "aafaddc9-749c-510e-ac4f-586e18779b91"
version = "0.2.2"

[[deps.ChainRules]]
deps = ["Adapt", "ChainRulesCore", "Compat", "Distributed", "GPUArraysCore", "IrrationalConstants", "LinearAlgebra", "Random", "RealDot", "SparseArrays", "Statistics", "StructArrays"]
git-tree-sha1 = "b97807637619f6ef2b519b46bde368f758734bc3"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.44.4"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "80ca332f6dcb2508adba68f22f551adb2d00a624"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.3"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "38f7a08f19d8810338d4f5085211c7dfa5d5bdd8"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.4"

[[deps.Clustering]]
deps = ["Distances", "LinearAlgebra", "NearestNeighbors", "Printf", "SparseArrays", "Statistics", "StatsBase"]
git-tree-sha1 = "75479b7df4167267d75294d14b58244695beb2ac"
uuid = "aaaa29a8-35af-508c-8bc3-b662a17a0fe5"
version = "0.14.2"

[[deps.CodecBzip2]]
deps = ["Bzip2_jll", "Libdl", "TranscodingStreams"]
git-tree-sha1 = "2e62a725210ce3c3c2e1a3080190e7ca491f18d7"
uuid = "523fee87-0ab8-5b00-afb7-3ecf72e48cfd"
version = "0.7.2"

[[deps.CodecZlib]]
deps = ["TranscodingStreams", "Zlib_jll"]
git-tree-sha1 = "ded953804d019afa9a3f98981d99b33e3db7b6da"
uuid = "944b1d66-785c-5afd-91f1-9de20f533193"
version = "0.7.0"

[[deps.ColorSchemes]]
deps = ["ColorTypes", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Random"]
git-tree-sha1 = "1fd869cc3875b57347f7027521f561cf46d1fcd8"
uuid = "35d6a980-a343-548e-a6ea-1d62b119f2f4"
version = "3.19.0"

[[deps.ColorTypes]]
deps = ["FixedPointNumbers", "Random"]
git-tree-sha1 = "eb7f0f8307f71fac7c606984ea5fb2817275d6e4"
uuid = "3da002f7-5984-5a60-b8a6-cbb66c0b333f"
version = "0.11.4"

[[deps.ColorVectorSpace]]
deps = ["ColorTypes", "FixedPointNumbers", "LinearAlgebra", "SpecialFunctions", "Statistics", "TensorCore"]
git-tree-sha1 = "d08c20eef1f2cbc6e60fd3612ac4340b89fea322"
uuid = "c3611d14-8923-5661-9e6a-0046d554d3a4"
version = "0.9.9"

[[deps.Colors]]
deps = ["ColorTypes", "FixedPointNumbers", "Reexport"]
git-tree-sha1 = "417b0ed7b8b838aa6ca0a87aadf1bb9eb111ce40"
uuid = "5ae59095-9a9b-59fe-a467-6f913c188581"
version = "0.12.8"

[[deps.CommonSubexpressions]]
deps = ["MacroTools", "Test"]
git-tree-sha1 = "7b8a93dba8af7e3b42fecabf646260105ac373f7"
uuid = "bbf7d656-a473-5ed7-a52c-81e309532950"
version = "0.3.0"

[[deps.Compat]]
deps = ["Dates", "LinearAlgebra", "UUIDs"]
git-tree-sha1 = "5856d3031cdb1f3b2b6340dfdc66b6d9a149a374"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.2.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"
version = "0.5.2+0"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.ConstructionBase]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "fb21ddd70a051d882a1686a5a550990bbe371a95"
uuid = "187b0558-2788-49d3-abe0-74a17ed4e7c9"
version = "1.4.1"

[[deps.Contour]]
git-tree-sha1 = "d05d9e7b7aedff4e5b51a029dced05cfb6125781"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.6.2"

[[deps.CoordinateTransformations]]
deps = ["LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "681ea870b918e7cff7111da58791d7f718067a19"
uuid = "150eb455-5306-5404-9cee-2592286d6298"
version = "0.6.2"

[[deps.CustomUnitRanges]]
git-tree-sha1 = "1a3f97f907e6dd8983b744d2642651bb162a3f7a"
uuid = "dc8bdbbb-1ca9-579f-8c36-e416f6a65cce"
version = "1.0.2"

[[deps.DataAPI]]
git-tree-sha1 = "fb5f5316dd3fd4c5e7c30a24d50643b73e37cd40"
uuid = "9a962f9c-6df0-11e9-0e5d-c546b8b5ee8a"
version = "1.10.0"

[[deps.DataStructures]]
deps = ["Compat", "InteractiveUtils", "OrderedCollections"]
git-tree-sha1 = "d1fff3a548102f48987a52a2e0d114fa97d730f0"
uuid = "864edb3b-99cc-5e75-8d2d-829cb0a9cfe8"
version = "0.18.13"

[[deps.DataValueInterfaces]]
git-tree-sha1 = "bfc1187b79289637fa0ef6d4436ebdfe6905cbd6"
uuid = "e2d170a0-9d28-54be-80f0-106bbe20a464"
version = "1.0.0"

[[deps.Dates]]
deps = ["Printf"]
uuid = "ade2ca70-3891-5945-98fb-dc099432e06a"

[[deps.DelimitedFiles]]
deps = ["Mmap"]
uuid = "8bb1440f-4735-579b-a4ab-409b98df4dab"

[[deps.DensityInterface]]
deps = ["InverseFunctions", "Test"]
git-tree-sha1 = "80c3e8639e3353e5d2912fb3a1916b8455e2494b"
uuid = "b429d917-457f-4dbc-8f4c-0cc954292b1d"
version = "0.4.0"

[[deps.DiffResults]]
deps = ["StaticArrays"]
git-tree-sha1 = "c18e98cba888c6c25d1c3b048e4b3380ca956805"
uuid = "163ba53b-c6d8-5494-b064-1a9d43ac40c5"
version = "1.0.3"

[[deps.DiffRules]]
deps = ["IrrationalConstants", "LogExpFunctions", "NaNMath", "Random", "SpecialFunctions"]
git-tree-sha1 = "992a23afdb109d0d2f8802a30cf5ae4b1fe7ea68"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.1"

[[deps.Distances]]
deps = ["LinearAlgebra", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "3258d0659f812acde79e8a74b11f17ac06d0ca04"
uuid = "b4f34e82-e78d-54a5-968a-f98e89d6e8f7"
version = "0.10.7"

[[deps.Distributed]]
deps = ["Random", "Serialization", "Sockets"]
uuid = "8ba89e20-285c-5b6f-9357-94700520ee1b"

[[deps.Distributions]]
deps = ["ChainRulesCore", "DensityInterface", "FillArrays", "LinearAlgebra", "PDMats", "Printf", "QuadGK", "Random", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "StatsFuns", "Test"]
git-tree-sha1 = "334a5896c1534bb1aa7aa2a642d30ba7707357ef"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.68"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "5158c2b41018c5f7eb1470d558127ac274eca0c9"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.9.1"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"
version = "1.6.0"

[[deps.DualNumbers]]
deps = ["Calculus", "NaNMath", "SpecialFunctions"]
git-tree-sha1 = "5837a837389fccf076445fce071c8ddaea35a566"
uuid = "fa6b7ba4-c1ee-5f82-b5fc-ecf0adba8f74"
version = "0.6.8"

[[deps.EarCut_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3f3a2501fa7236e9b911e0f7a588c657e822bb6d"
uuid = "5ae413db-bbd1-5e63-b57d-d24a61df00f5"
version = "2.2.3+0"

[[deps.Expat_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bad72f730e9e91c08d9427d5e8db95478a3c323d"
uuid = "2e619515-83b5-522b-bb60-26c02a35a201"
version = "2.4.8+0"

[[deps.ExprTools]]
git-tree-sha1 = "56559bbef6ca5ea0c0818fa5c90320398a6fbf8d"
uuid = "e2ba6199-217a-4e67-a87a-7c52f15ade04"
version = "0.1.8"

[[deps.Extents]]
git-tree-sha1 = "5e1e4c53fa39afe63a7d356e30452249365fba99"
uuid = "411431e0-e8b7-467b-b5e0-f676ba4f2910"
version = "0.1.1"

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libaom_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "ccd479984c7838684b3ac204b716c89955c76623"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.2+0"

[[deps.FFTViews]]
deps = ["CustomUnitRanges", "FFTW"]
git-tree-sha1 = "cbdf14d1e8c7c8aacbe8b19862e0179fd08321c2"
uuid = "4f61f5a4-77b1-5117-aa51-3ab5ef4ef0cd"
version = "0.3.2"

[[deps.FFTW]]
deps = ["AbstractFFTs", "FFTW_jll", "LinearAlgebra", "MKL_jll", "Preferences", "Reexport"]
git-tree-sha1 = "90630efff0894f8142308e334473eba54c433549"
uuid = "7a1cc6ca-52ef-59f5-83cd-3a7055c09341"
version = "1.5.0"

[[deps.FFTW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c6033cc3892d0ef5bb9cd29b7f2f0331ea5184ea"
uuid = "f5851436-0d7a-5f13-b9de-f02708fd171a"
version = "3.3.10+0"

[[deps.FastClosures]]
git-tree-sha1 = "acebe244d53ee1b461970f8910c235b259e772ef"
uuid = "9aa1b823-49e4-5ca5-8b0f-3971ec8bab6a"
version = "0.3.2"

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "94f5101b96d2d968ace56f7f2db19d0a5f592e28"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.15.0"

[[deps.FileWatching]]
uuid = "7b1f6079-737a-58dc-b8bc-7a2ca5c1b5ee"

[[deps.FillArrays]]
deps = ["LinearAlgebra", "Random", "SparseArrays", "Statistics"]
git-tree-sha1 = "246621d23d1f43e3b9c368bf3b72b2331a27c286"
uuid = "1a297f60-69ca-5386-bcde-b61e274b549b"
version = "0.13.2"

[[deps.FixedPointNumbers]]
deps = ["Statistics"]
git-tree-sha1 = "335bfdceacc84c5cdf16aadc768aa5ddfc5383cc"
uuid = "53c48c17-4a7d-5ca2-90c5-79b7896eea93"
version = "0.8.4"

[[deps.Flux]]
deps = ["Adapt", "ArrayInterface", "CUDA", "ChainRulesCore", "Functors", "LinearAlgebra", "MLUtils", "MacroTools", "NNlib", "NNlibCUDA", "Optimisers", "ProgressLogging", "Random", "Reexport", "SparseArrays", "SpecialFunctions", "Statistics", "StatsBase", "Test", "Zygote"]
git-tree-sha1 = "9b5419ad6f043ac2b52f1b7f9a8ecb8762231214"
uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c"
version = "0.13.5"

[[deps.Fontconfig_jll]]
deps = ["Artifacts", "Bzip2_jll", "Expat_jll", "FreeType2_jll", "JLLWrappers", "Libdl", "Libuuid_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "21efd19106a55620a188615da6d3d06cd7f6ee03"
uuid = "a3f928ae-7b40-5064-980b-68af3947d34b"
version = "2.13.93+0"

[[deps.Formatting]]
deps = ["Printf"]
git-tree-sha1 = "8339d61043228fdd3eb658d86c926cb282ae72a8"
uuid = "59287772-0a20-5a39-b81b-1366585eb4c0"
version = "0.4.2"

[[deps.ForwardDiff]]
deps = ["CommonSubexpressions", "DiffResults", "DiffRules", "LinearAlgebra", "LogExpFunctions", "NaNMath", "Preferences", "Printf", "Random", "SpecialFunctions", "StaticArrays"]
git-tree-sha1 = "187198a4ed8ccd7b5d99c41b69c679269ea2b2d4"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.32"

[[deps.FrankWolfe]]
deps = ["Arpack", "GenericSchur", "Hungarian", "LinearAlgebra", "MathOptInterface", "Printf", "ProgressMeter", "Random", "Setfield", "SparseArrays", "TimerOutputs"]
git-tree-sha1 = "ae0ac93f6e01ff0a9174f96dbb6985ac02ebf73a"
uuid = "f55ce6ea-fdc5-4628-88c5-0087fe54bd30"
version = "0.2.11"

[[deps.FreeType2_jll]]
deps = ["Artifacts", "Bzip2_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "87eb71354d8ec1a96d4a7636bd57a7347dde3ef9"
uuid = "d7e528f0-a631-5988-bf34-fe36492bcfd7"
version = "2.10.4+0"

[[deps.FriBidi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "aa31987c2ba8704e23c6c8ba8a4f769d5d7e4f91"
uuid = "559328eb-81f9-559d-9380-de523a88c83c"
version = "1.0.10+0"

[[deps.Functors]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "a2657dd0f3e8a61dbe70fc7c122038bd33790af5"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.3.0"

[[deps.Future]]
deps = ["Random"]
uuid = "9fa8497b-333b-5362-9e8d-4d0656e87820"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "d972031d28c8c8d9d7b41a536ad7bb0c2579caca"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.8+0"

[[deps.GLPK]]
deps = ["GLPK_jll", "MathOptInterface"]
git-tree-sha1 = "c3cc0a7a4e021620f1c0e67679acdbf1be311eb0"
uuid = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
version = "1.0.1"

[[deps.GLPK_jll]]
deps = ["Artifacts", "GMP_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "fe68622f32828aa92275895fdb324a85894a5b1b"
uuid = "e8aa6df9-e6ca-548a-97ff-1f85fc5b8b98"
version = "5.0.1+0"

[[deps.GMP_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "781609d7-10c4-51f6-84f2-b8444358ff6d"
version = "6.2.1+2"

[[deps.GPUArrays]]
deps = ["Adapt", "GPUArraysCore", "LLVM", "LinearAlgebra", "Printf", "Random", "Reexport", "Serialization", "Statistics"]
git-tree-sha1 = "45d7deaf05cbb44116ba785d147c518ab46352d7"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.5.0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "6872f5ec8fd1a38880f027a26739d42dcda6691f"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.2"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "122d7bcc92abf94cf1a86281ad7a4d0e838ab9e0"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.16.3"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "cf0a9940f250dc3cb6cc6c6821b4bf8a4286cf9c"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.66.2"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "2d908286d120c584abbe7621756c341707096ba4"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.66.2+0"

[[deps.GenericSchur]]
deps = ["LinearAlgebra", "Printf"]
git-tree-sha1 = "fb69b2a645fa69ba5f474af09221b9308b160ce6"
uuid = "c145ed77-6b09-5dd9-b285-bf645a82121e"
version = "0.5.3"

[[deps.GeoInterface]]
deps = ["Extents"]
git-tree-sha1 = "fb28b5dc239d0174d7297310ef7b84a11804dfab"
uuid = "cf35fbd7-0cd7-5166-be24-54bfbe79505f"
version = "1.0.1"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "GeoInterface", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "a7a97895780dab1085a97769316aa348830dc991"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.3"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

[[deps.Ghostscript_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78e2c69783c9753a91cdae88a8d432be85a2ab5e"
uuid = "61579ee1-b43e-5ca0-a5da-69d92c66a64b"
version = "9.55.0+0"

[[deps.Glib_jll]]
deps = ["Artifacts", "Gettext_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Libiconv_jll", "Libmount_jll", "PCRE_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "a32d672ac2c967f3deb8a81d828afc739c838a06"
uuid = "7746bdde-850d-59dc-9ae8-88ece973131d"
version = "2.68.3+2"

[[deps.Graphics]]
deps = ["Colors", "LinearAlgebra", "NaNMath"]
git-tree-sha1 = "d61890399bc535850c4bf08e4e0d3a7ad0f21cbd"
uuid = "a2bd30eb-e257-5431-a919-1863eab51364"
version = "1.1.2"

[[deps.Graphite2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "344bf40dcab1073aca04aa0df4fb092f920e4011"
uuid = "3b182d85-2403-5c21-9c21-1e1f0cc25472"
version = "1.3.14+0"

[[deps.Graphs]]
deps = ["ArnoldiMethod", "Compat", "DataStructures", "Distributed", "Inflate", "LinearAlgebra", "Random", "SharedArrays", "SimpleTraits", "SparseArrays", "Statistics"]
git-tree-sha1 = "a6d30bdc378d340912f48abf01281aab68c0dec8"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.2"

[[deps.GridGraphs]]
deps = ["DataStructures", "Graphs", "SparseArrays"]
git-tree-sha1 = "839a435ae8ac8e2d0457c78908f8e6757fbbb611"
uuid = "dd2b58c7-5af7-4f17-9e46-57c68ac813fb"
version = "0.7.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "CodecZlib", "Dates", "IniFile", "Logging", "LoggingExtras", "MbedTLS", "NetworkOptions", "Random", "SimpleBufferStream", "Sockets", "URIs", "UUIDs"]
git-tree-sha1 = "303a225c6fbd7647aae030730d48239552e4d006"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "1.3.1"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.Hungarian]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "371a7df7a6cce5909d6c576f234a2da2e3fa0c98"
uuid = "e91730f6-4275-51fb-a7a0-7064cfbd3b39"
version = "0.6.0"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "OpenLibm_jll", "SpecialFunctions", "Test"]
git-tree-sha1 = "709d864e3ed6e3545230601f94e11ebc65994641"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.11"

[[deps.Hyperscript]]
deps = ["Test"]
git-tree-sha1 = "8d511d5b81240fc8e6802386302675bdf47737b9"
uuid = "47d2ed2b-36de-50cf-bf87-49c2cf4b8b91"
version = "0.0.4"

[[deps.HypertextLiteral]]
deps = ["Tricks"]
git-tree-sha1 = "c47c5fa4c5308f27ccaac35504858d8914e102f9"
uuid = "ac1192a8-f4b3-4bfe-ba22-af5b92cd3ab2"
version = "0.9.4"

[[deps.IOCapture]]
deps = ["Logging", "Random"]
git-tree-sha1 = "f7be53659ab06ddc986428d3a9dcc95f6fa6705a"
uuid = "b5f81e59-6552-4d32-b1f0-c071b021bf89"
version = "0.2.2"

[[deps.IRTools]]
deps = ["InteractiveUtils", "MacroTools", "Test"]
git-tree-sha1 = "af14a478780ca78d5eb9908b263023096c2b9d64"
uuid = "7869d1d1-7146-5819-86e3-90919afe41df"
version = "0.4.6"

[[deps.IfElse]]
git-tree-sha1 = "debdd00ffef04665ccbb3e150747a77560e8fad1"
uuid = "615f187c-cbe4-4ef1-ba3b-2fcf58d6d173"
version = "0.1.1"

[[deps.ImageAxes]]
deps = ["AxisArrays", "ImageBase", "ImageCore", "Reexport", "SimpleTraits"]
git-tree-sha1 = "c54b581a83008dc7f292e205f4c409ab5caa0f04"
uuid = "2803e5a7-5153-5ecf-9a86-9b4c37f5f5ac"
version = "0.6.10"

[[deps.ImageBase]]
deps = ["ImageCore", "Reexport"]
git-tree-sha1 = "b51bb8cae22c66d0f6357e3bcb6363145ef20835"
uuid = "c817782e-172a-44cc-b673-b171935fbb9e"
version = "0.1.5"

[[deps.ImageContrastAdjustment]]
deps = ["ImageCore", "ImageTransformations", "Parameters"]
git-tree-sha1 = "0d75cafa80cf22026cea21a8e6cf965295003edc"
uuid = "f332f351-ec65-5f6a-b3d1-319c6670881a"
version = "0.3.10"

[[deps.ImageCore]]
deps = ["AbstractFFTs", "ColorVectorSpace", "Colors", "FixedPointNumbers", "Graphics", "MappedArrays", "MosaicViews", "OffsetArrays", "PaddedViews", "Reexport"]
git-tree-sha1 = "acf614720ef026d38400b3817614c45882d75500"
uuid = "a09fc81d-aa75-5fe9-8630-4744c3626534"
version = "0.9.4"

[[deps.ImageDistances]]
deps = ["Distances", "ImageCore", "ImageMorphology", "LinearAlgebra", "Statistics"]
git-tree-sha1 = "b1798a4a6b9aafb530f8f0c4a7b2eb5501e2f2a3"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.16"

[[deps.ImageFiltering]]
deps = ["CatIndices", "ComputationalResources", "DataStructures", "FFTViews", "FFTW", "ImageBase", "ImageCore", "LinearAlgebra", "OffsetArrays", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "TiledIteration"]
git-tree-sha1 = "15bd05c1c0d5dbb32a9a3d7e0ad2d50dd6167189"
uuid = "6a3955dd-da59-5b1f-98d4-e7296123deb5"
version = "0.7.1"

[[deps.ImageIO]]
deps = ["FileIO", "IndirectArrays", "JpegTurbo", "LazyModules", "Netpbm", "OpenEXR", "PNGFiles", "QOI", "Sixel", "TiffImages", "UUIDs"]
git-tree-sha1 = "342f789fd041a55166764c351da1710db97ce0e0"
uuid = "82e4d734-157c-48bb-816b-45c225c6df19"
version = "0.6.6"

[[deps.ImageMagick]]
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils", "Libdl", "Pkg", "Random"]
git-tree-sha1 = "5bc1cb62e0c5f1005868358db0692c994c3a13c6"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.1"

[[deps.ImageMagick_jll]]
deps = ["Artifacts", "Ghostscript_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "f025b79883f361fa1bd80ad132773161d231fd9f"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.12+2"

[[deps.ImageMetadata]]
deps = ["AxisArrays", "ImageAxes", "ImageBase", "ImageCore"]
git-tree-sha1 = "36cbaebed194b292590cba2593da27b34763804a"
uuid = "bc367c6b-8a6b-528e-b4bd-a4b897500b49"
version = "0.9.8"

[[deps.ImageMorphology]]
deps = ["ImageCore", "LinearAlgebra", "Requires", "TiledIteration"]
git-tree-sha1 = "e7c68ab3df4a75511ba33fc5d8d9098007b579a8"
uuid = "787d08f9-d448-5407-9aad-5290dd7ab264"
version = "0.3.2"

[[deps.ImageQualityIndexes]]
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "LazyModules", "OffsetArrays", "Statistics"]
git-tree-sha1 = "0c703732335a75e683aec7fdfc6d5d1ebd7c596f"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.3"

[[deps.ImageSegmentation]]
deps = ["Clustering", "DataStructures", "Distances", "Graphs", "ImageCore", "ImageFiltering", "ImageMorphology", "LinearAlgebra", "MetaGraphs", "RegionTrees", "SimpleWeightedGraphs", "StaticArrays", "Statistics"]
git-tree-sha1 = "36832067ea220818d105d718527d6ed02385bf22"
uuid = "80713f31-8817-5129-9cf8-209ff8fb23e1"
version = "1.7.0"

[[deps.ImageShow]]
deps = ["Base64", "FileIO", "ImageBase", "ImageCore", "OffsetArrays", "StackViews"]
git-tree-sha1 = "b563cf9ae75a635592fc73d3eb78b86220e55bd8"
uuid = "4e3cecfd-b093-5904-9786-8bbb286a6a31"
version = "0.3.6"

[[deps.ImageTransformations]]
deps = ["AxisAlgorithms", "ColorVectorSpace", "CoordinateTransformations", "ImageBase", "ImageCore", "Interpolations", "OffsetArrays", "Rotations", "StaticArrays"]
git-tree-sha1 = "8717482f4a2108c9358e5c3ca903d3a6113badc9"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.9.5"

[[deps.Images]]
deps = ["Base64", "FileIO", "Graphics", "ImageAxes", "ImageBase", "ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "ImageIO", "ImageMagick", "ImageMetadata", "ImageMorphology", "ImageQualityIndexes", "ImageSegmentation", "ImageShow", "ImageTransformations", "IndirectArrays", "IntegralArrays", "Random", "Reexport", "SparseArrays", "StaticArrays", "Statistics", "StatsBase", "TiledIteration"]
git-tree-sha1 = "03d1301b7ec885b266c0f816f338368c6c0b81bd"
uuid = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
version = "0.25.2"

[[deps.Imath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "87f7662e03a649cffa2e05bf19c303e168732d3e"
uuid = "905a6f67-0a94-5f89-b386-d35d92009cd1"
version = "3.1.2+0"

[[deps.IndirectArrays]]
git-tree-sha1 = "012e604e1c7458645cb8b436f8fba789a51b257f"
uuid = "9b13fd28-a010-5f03-acff-a1bbcff69959"
version = "1.0.0"

[[deps.InferOpt]]
deps = ["ChainRulesCore", "FrankWolfe", "Krylov", "LinearAlgebra", "LinearOperators", "Random", "SimpleTraits", "SparseArrays", "Statistics", "StatsBase", "Test"]
git-tree-sha1 = "1bc53561ad21d0f58cef3f4ea7417476be12e2bb"
uuid = "4846b161-c94e-4150-8dac-c7ae193c601f"
version = "0.3.1"

[[deps.Inflate]]
git-tree-sha1 = "5cd07aab533df5170988219191dfad0519391428"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.3"

[[deps.IniFile]]
git-tree-sha1 = "f550e6e32074c939295eb5ea6de31849ac2c9625"
uuid = "83e8ac13-25f8-5344-8a64-a9f2b223428f"
version = "0.5.1"

[[deps.IntegralArrays]]
deps = ["ColorTypes", "FixedPointNumbers", "IntervalSets"]
git-tree-sha1 = "be8e690c3973443bec584db3346ddc904d4884eb"
uuid = "1d092043-8f09-5a30-832f-7509e371ab51"
version = "0.1.5"

[[deps.IntelOpenMP_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "d979e54b71da82f3a65b62553da4fc3d18c9004c"
uuid = "1d5cc7b8-4909-519e-a0f8-d0f5ad9712d0"
version = "2018.0.3+2"

[[deps.InteractiveUtils]]
deps = ["Markdown"]
uuid = "b77e0a4c-d291-57a0-90e8-8db25a27a240"

[[deps.Interpolations]]
deps = ["Adapt", "AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "64f138f9453a018c8f3562e7bae54edc059af249"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.14.4"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "076bb0da51a8c8d1229936a1af7bdfacd65037e1"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.2"

[[deps.InverseFunctions]]
deps = ["Test"]
git-tree-sha1 = "b3364212fb5d870f724876ffcd34dd8ec6d98918"
uuid = "3587e190-3f89-42d0-90ee-14403ec27112"
version = "0.1.7"

[[deps.IrrationalConstants]]
git-tree-sha1 = "7fd44fd4ff43fc60815f8e764c0f352b83c49151"
uuid = "92d709cd-6900-40b7-9082-c6be49f344b6"
version = "0.1.1"

[[deps.IterTools]]
git-tree-sha1 = "fa6287a4469f5e048d763df38279ee729fbd44e5"
uuid = "c8e1da08-722c-5040-9ed9-7db0dc04731e"
version = "1.4.0"

[[deps.IteratorInterfaceExtensions]]
git-tree-sha1 = "a3f24677c21f5bbe9d2a714f95dcd58337fb2856"
uuid = "82899510-4779-5014-852e-03e436cf321d"
version = "1.0.0"

[[deps.JLD2]]
deps = ["FileIO", "MacroTools", "Mmap", "OrderedCollections", "Pkg", "Printf", "Reexport", "TranscodingStreams", "UUIDs"]
git-tree-sha1 = "81b9477b49402b47fbe7f7ae0b252077f53e4a08"
uuid = "033835bb-8acc-5ee8-8aae-3f567f8a3819"
version = "0.4.22"

[[deps.JLLWrappers]]
deps = ["Preferences"]
git-tree-sha1 = "abc9885a7ca2052a736a600f7fa66209f96506e1"
uuid = "692b3bcd-3c85-4b1f-b108-f13ce0eb3210"
version = "1.4.1"

[[deps.JSON]]
deps = ["Dates", "Mmap", "Parsers", "Unicode"]
git-tree-sha1 = "3c837543ddb02250ef42f4738347454f95079d4e"
uuid = "682c06a0-de6a-54ab-a142-c8b1cf79cde6"
version = "0.21.3"

[[deps.JpegTurbo]]
deps = ["CEnum", "FileIO", "ImageCore", "JpegTurbo_jll", "TOML"]
git-tree-sha1 = "a77b273f1ddec645d1b7c4fd5fb98c8f90ad10a5"
uuid = "b835a17e-a41a-41e7-81f0-2f016b05efe0"
version = "0.1.1"

[[deps.JpegTurbo_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b53380851c6e6664204efb2e62cd24fa5c47e4ba"
uuid = "aacddb02-875f-59d6-b918-886e6ef4fbf8"
version = "2.1.2+0"

[[deps.JuMP]]
deps = ["LinearAlgebra", "MathOptInterface", "MutableArithmetics", "OrderedCollections", "Printf", "SparseArrays"]
git-tree-sha1 = "81e17aab8447b7af79ee4f5e0450922991969dd2"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.2.1"

[[deps.Krylov]]
deps = ["LinearAlgebra", "Printf", "SparseArrays"]
git-tree-sha1 = "a2327039e1c84615e22d662adb3df113caf44b70"
uuid = "ba0b0d4f-ebba-5204-a429-3ac8c609bfb7"
version = "0.8.3"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

[[deps.LDLFactorizations]]
deps = ["AMD", "LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "736e01b9b2d443c4e3351aebe551b8a374ab9c05"
uuid = "40e66cde-538c-5869-a4ad-c39174c6795b"
version = "0.8.2"

[[deps.LERC_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "bf36f528eec6634efc60d7ec062008f171071434"
uuid = "88015f11-f218-50d7-93a8-a6af411a945d"
version = "3.0.0+1"

[[deps.LLVM]]
deps = ["CEnum", "LLVMExtra_jll", "Libdl", "Printf", "Unicode"]
git-tree-sha1 = "e7e9184b0bf0158ac4e4aa9daf00041b5909bf1a"
uuid = "929cbde3-209d-540e-8aea-75f648917ca0"
version = "4.14.0"

[[deps.LLVMExtra_jll]]
deps = ["Artifacts", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg", "TOML"]
git-tree-sha1 = "771bfe376249626d3ca12bcd58ba243d3f961576"
uuid = "dad2f222-ce93-54a1-a47d-0025e8a3acab"
version = "0.0.16+0"

[[deps.LZO_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e5b909bcf985c5e2605737d2ce278ed791b89be6"
uuid = "dd4b983a-f0e5-5f8d-a1b7-129d4a5fb1ac"
version = "2.10.1+0"

[[deps.LaTeXStrings]]
git-tree-sha1 = "f2355693d6778a178ade15952b7ac47a4ff97996"
uuid = "b964fa9f-0449-5b57-a5c2-d3ea65f4040f"
version = "1.3.0"

[[deps.Latexify]]
deps = ["Formatting", "InteractiveUtils", "LaTeXStrings", "MacroTools", "Markdown", "Printf", "Requires"]
git-tree-sha1 = "1a43be956d433b5d0321197150c2f94e16c0aaa0"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.16"

[[deps.LazyArtifacts]]
deps = ["Artifacts", "Pkg"]
uuid = "4af54fe1-eca0-43a8-85a7-787d91b784e3"

[[deps.LazyModules]]
git-tree-sha1 = "a560dd966b386ac9ae60bdd3a3d3a326062d3c3e"
uuid = "8cdb02fc-e678-4876-92c5-9defec4f444e"
version = "0.3.1"

[[deps.LibCURL]]
deps = ["LibCURL_jll", "MozillaCACerts_jll"]
uuid = "b27032c2-a3e7-50c8-80cd-2d36dbcbfd21"
version = "0.6.3"

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"
version = "7.84.0+0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"
version = "1.10.2+0"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.Libffi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "0b4a5d71f3e5200a7dff793393e09dfc2d874290"
uuid = "e9f186c6-92d2-5b65-8a66-fee21dc1b490"
version = "3.2.2+1"

[[deps.Libgcrypt_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgpg_error_jll", "Pkg"]
git-tree-sha1 = "64613c82a59c120435c067c2b809fc61cf5166ae"
uuid = "d4300ac3-e22c-5743-9152-c294e39db1e4"
version = "1.8.7+0"

[[deps.Libglvnd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll", "Xorg_libXext_jll"]
git-tree-sha1 = "7739f837d6447403596a75d19ed01fd08d6f56bf"
uuid = "7e76a0d4-f3c7-5321-8279-8d96eeed0f29"
version = "1.3.0+3"

[[deps.Libgpg_error_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "c333716e46366857753e273ce6a69ee0945a6db9"
uuid = "7add5ba3-2f88-524e-9cd5-f83b8a55f7b8"
version = "1.42.0+0"

[[deps.Libiconv_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "42b62845d70a619f063a7da093d995ec8e15e778"
uuid = "94ce4f54-9a6c-5748-9c1c-f9c7231a4531"
version = "1.16.1+1"

[[deps.Libmount_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9c30530bf0effd46e15e0fdcf2b8636e78cbbd73"
uuid = "4b2f31a3-9ecc-558c-b454-b3730dcb73e9"
version = "2.35.0+0"

[[deps.Libtiff_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "LERC_jll", "Libdl", "Pkg", "Zlib_jll", "Zstd_jll"]
git-tree-sha1 = "3eb79b0ca5764d4799c06699573fd8f533259713"
uuid = "89763e89-9b03-5906-acba-b20f662cd828"
version = "4.4.0+0"

[[deps.Libuuid_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "7f3efec06033682db852f8b3bc3c1d2b0a0ab066"
uuid = "38a345b3-de98-5d2b-a5d3-14cd9215e700"
version = "2.36.0+0"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.LinearOperators]]
deps = ["FastClosures", "LDLFactorizations", "LinearAlgebra", "Printf", "SparseArrays", "TimerOutputs"]
git-tree-sha1 = "b404faa9b85e62c0eeec7a600d5b4316c58215ed"
uuid = "5c8ed15e-5a4c-59e4-a42b-c7e8811fb125"
version = "2.3.2"

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "94d9c52ca447e23eac0c0f074effbcd38830deb5"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.18"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.LoggingExtras]]
deps = ["Dates", "Logging"]
git-tree-sha1 = "5d4d2d9904227b8bd66386c1138cf4d5ffa826bf"
uuid = "e6f89c97-d47a-5376-807f-9c37f3926c36"
version = "0.4.9"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "41d162ae9c868218b1f3fe78cba878aa348c2d26"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.1.0+0"

[[deps.MLUtils]]
deps = ["ChainRulesCore", "DelimitedFiles", "Random", "ShowCases", "Statistics", "StatsBase"]
git-tree-sha1 = "c92a10a2492dffac0e152a19d5ffd99a5030349a"
uuid = "f1d291b0-491e-4a28-83b9-f70985020b54"
version = "0.2.1"

[[deps.MacroTools]]
deps = ["Markdown", "Random"]
git-tree-sha1 = "3d3e902b31198a27340d0bf00d6ac452866021cf"
uuid = "1914dd2f-81c6-5fcd-8719-6d5c9610ff09"
version = "0.5.9"

[[deps.MappedArrays]]
git-tree-sha1 = "e8b359ef06ec72e8c030463fe02efe5527ee5142"
uuid = "dbb5928d-eab1-5f90-85c2-b9b0edb7c900"
version = "0.4.1"

[[deps.Markdown]]
deps = ["Base64"]
uuid = "d6f4376e-aef5-505a-96c1-9c027394607a"

[[deps.MathOptInterface]]
deps = ["BenchmarkTools", "CodecBzip2", "CodecZlib", "DataStructures", "ForwardDiff", "JSON", "LinearAlgebra", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions", "Test", "Unicode"]
git-tree-sha1 = "b79f525737702ff2a3f2005a0823e3518ce8b04c"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.7.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "MozillaCACerts_jll", "Random", "Sockets"]
git-tree-sha1 = "d9ab10da9de748859a7780338e1d6566993d1f25"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.1.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"
version = "2.28.0+0"

[[deps.Measures]]
git-tree-sha1 = "e498ddeee6f9fdb4551ce855a46f54dbd900245f"
uuid = "442fdcdd-2543-5da2-b0f3-8c86c306513e"
version = "0.3.1"

[[deps.MetaGraphs]]
deps = ["Graphs", "JLD2", "Random"]
git-tree-sha1 = "2af69ff3c024d13bde52b34a2a7d6887d4e7b438"
uuid = "626554b9-1ddb-594c-aa3c-2596fe9399a5"
version = "0.7.1"

[[deps.Missings]]
deps = ["DataAPI"]
git-tree-sha1 = "bf210ce90b6c9eed32d25dbcae1ebc565df2687f"
uuid = "e1d29d7a-bbdc-5cf2-9ac0-f12de2c33e28"
version = "1.0.2"

[[deps.Mmap]]
uuid = "a63ad114-7e13-5084-954f-fe012c677804"

[[deps.MosaicViews]]
deps = ["MappedArrays", "OffsetArrays", "PaddedViews", "StackViews"]
git-tree-sha1 = "b34e3bc3ca7c94914418637cb10cc4d1d80d877d"
uuid = "e94cdb99-869f-56ef-bcf0-1ae2bcbe0389"
version = "0.3.3"

[[deps.MozillaCACerts_jll]]
uuid = "14a3606d-f60d-562e-9121-12d972cd8159"
version = "2022.2.1"

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4e675d6e9ec02061800d6cfb695812becbd03cdf"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.4"

[[deps.NNlib]]
deps = ["Adapt", "ChainRulesCore", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "415108fd88d6f55cedf7ee940c7d4b01fad85421"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.8.9"

[[deps.NNlibCUDA]]
deps = ["Adapt", "CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics"]
git-tree-sha1 = "4429261364c5ea5b7308aecaa10e803ace101631"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.2.4"

[[deps.NaNMath]]
deps = ["OpenLibm_jll"]
git-tree-sha1 = "a7c3d1da1189a1c2fe843a3bfa04d18d20eb3211"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.1"

[[deps.NearestNeighbors]]
deps = ["Distances", "StaticArrays"]
git-tree-sha1 = "0e353ed734b1747fc20cd4cba0edd9ac027eff6a"
uuid = "b8a86587-4115-5ab1-83bc-aa920d37bbce"
version = "0.4.11"

[[deps.Netpbm]]
deps = ["FileIO", "ImageCore"]
git-tree-sha1 = "18efc06f6ec36a8b801b23f076e3c6ac7c3bf153"
uuid = "f09324ee-3d7c-5217-9330-fc30815ba969"
version = "1.0.2"

[[deps.NetworkOptions]]
uuid = "ca575930-c2e3-43a9-ace4-1e988b2c1908"
version = "1.2.0"

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "1ea784113a6aa054c5ebd95945fa5e52c2f378e7"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.7"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"
version = "0.3.20+0"

[[deps.OpenEXR]]
deps = ["Colors", "FileIO", "OpenEXR_jll"]
git-tree-sha1 = "327f53360fdb54df7ecd01e96ef1983536d1e633"
uuid = "52e1d378-f018-4a11-a4be-720524705ac7"
version = "0.3.2"

[[deps.OpenEXR_jll]]
deps = ["Artifacts", "Imath_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "923319661e9a22712f24596ce81c54fc0366f304"
uuid = "18a262bb-aa17-5467-a713-aee519bc75cb"
version = "3.1.1+0"

[[deps.OpenJpeg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libtiff_jll", "LittleCMS_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "76374b6e7f632c130e78100b166e5a48464256f8"
uuid = "643b3616-a352-519d-856d-80112ee9badc"
version = "2.4.0+0"

[[deps.OpenLibm_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "05823500-19ac-5b8b-9628-191a04bc5112"
version = "0.8.1+0"

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e60321e3f2616584ff98f0a4f18d98ae6f89bbb3"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.17+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optimisers]]
deps = ["ChainRulesCore", "Functors", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "1ef34738708e3f31994b52693286dabcb3d29f6b"
uuid = "3bd65402-5787-11e9-1adc-39752487f4e2"
version = "0.2.9"

[[deps.Opus_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "51a08fb14ec28da2ec7a927c4337e4332c2a4720"
uuid = "91d4177d-7536-5919-b921-800302f37372"
version = "1.3.2+0"

[[deps.OrderedCollections]]
git-tree-sha1 = "85f8e6578bf1f9ee0d11e7bb1b1456435479d47c"
uuid = "bac558e1-5e72-5ebc-8fee-abe8a469f55d"
version = "1.4.1"

[[deps.PCRE_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b2a7af664e098055a7529ad1a900ded962bca488"
uuid = "2f80f16e-611a-54ab-bc61-aa92de5b98fc"
version = "8.44.0+0"

[[deps.PDMats]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "cf494dca75a69712a72b80bc48f59dcf3dea63ec"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.16"

[[deps.PNGFiles]]
deps = ["Base64", "CEnum", "ImageCore", "IndirectArrays", "OffsetArrays", "libpng_jll"]
git-tree-sha1 = "e925a64b8585aa9f4e3047b8d2cdc3f0e79fd4e4"
uuid = "f57f5aa1-a3ce-4bc8-8ab9-96f992907883"
version = "0.3.16"

[[deps.PaddedViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "03a7a85b76381a3d04c7a1656039197e70eda03d"
uuid = "5432bcbf-9aad-5242-b902-cca2824c8663"
version = "0.5.11"

[[deps.Parameters]]
deps = ["OrderedCollections", "UnPack"]
git-tree-sha1 = "34c0e9ad262e5f7fc75b10a9952ca7692cfc5fbe"
uuid = "d96e819e-fc66-5662-9728-84c9c7592b0a"
version = "0.12.3"

[[deps.Parsers]]
deps = ["Dates"]
git-tree-sha1 = "0044b23da09b5608b4ecacb4e5e6c6332f833a7e"
uuid = "69de0a69-1ddd-5017-9359-2bf0b02dc9f0"
version = "2.3.2"

[[deps.Pixman_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "b4f5d02549a10e20780a24fce72bea96b6329e29"
uuid = "30392449-352a-5448-841d-b1acce4e97dc"
version = "0.40.1+0"

[[deps.Pkg]]
deps = ["Artifacts", "Dates", "Downloads", "LibGit2", "Libdl", "Logging", "Markdown", "Printf", "REPL", "Random", "SHA", "Serialization", "TOML", "Tar", "UUIDs", "p7zip_jll"]
uuid = "44cfe95a-1eb2-52ea-b672-e2afdf69b78f"
version = "1.8.0"

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "f6cf8e7944e50901594838951729a1861e668cb8"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.3.2"

[[deps.PlotThemes]]
deps = ["PlotUtils", "Statistics"]
git-tree-sha1 = "8162b2f8547bc23876edd0c5181b27702ae58dce"
uuid = "ccf2f8ad-2431-5c83-bf29-c5338b663b6a"
version = "3.0.0"

[[deps.PlotUtils]]
deps = ["ColorSchemes", "Colors", "Dates", "Printf", "Random", "Reexport", "Statistics"]
git-tree-sha1 = "9888e59493658e476d3073f1ce24348bdc086660"
uuid = "995b91a9-d308-5afd-9ec6-746e21dbc043"
version = "1.3.0"

[[deps.Plots]]
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "LaTeXStrings", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "a19652399f43938413340b2068e11e55caa46b65"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.31.7"

[[deps.PlutoUI]]
deps = ["AbstractPlutoDingetjes", "Base64", "ColorTypes", "Dates", "Hyperscript", "HypertextLiteral", "IOCapture", "InteractiveUtils", "JSON", "Logging", "Markdown", "Random", "Reexport", "UUIDs"]
git-tree-sha1 = "8d1f54886b9037091edf146b517989fc4a09efec"
uuid = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
version = "0.7.39"

[[deps.Poppler_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "OpenJpeg_jll", "Pkg", "libpng_jll"]
git-tree-sha1 = "e11443687ac151ac6ef6699eb75f964bed8e1faa"
uuid = "9c32591e-4766-534b-9725-b71a8799265b"
version = "0.87.0+2"

[[deps.Preferences]]
deps = ["TOML"]
git-tree-sha1 = "47e5f437cc0e7ef2ce8406ce1e7e24d44915f88d"
uuid = "21216c6a-2e73-6563-6e65-726566657250"
version = "1.3.0"

[[deps.Printf]]
deps = ["Unicode"]
uuid = "de0858da-6303-5e67-8744-51eddeeeb8d7"

[[deps.Profile]]
deps = ["Printf"]
uuid = "9abbd945-dff8-562f-b5e8-e1ebf5ef1b79"

[[deps.ProgressLogging]]
deps = ["Logging", "SHA", "UUIDs"]
git-tree-sha1 = "80d919dee55b9c50e8d9e2da5eeafff3fe58b539"
uuid = "33c8b6b6-d38a-422a-b730-caa89a2f386c"
version = "0.1.4"

[[deps.ProgressMeter]]
deps = ["Distributed", "Printf"]
git-tree-sha1 = "d7a7aef8f8f2d537104f170139553b14dfe39fe9"
uuid = "92933f4c-e287-5a05-a399-4b506db050ca"
version = "1.7.2"

[[deps.QOI]]
deps = ["ColorTypes", "FileIO", "FixedPointNumbers"]
git-tree-sha1 = "18e8f4d1426e965c7b532ddd260599e1510d26ce"
uuid = "4b34888f-f399-49d4-9bb3-47ed5cae4e65"
version = "1.0.0"

[[deps.Qt5Base_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Fontconfig_jll", "Glib_jll", "JLLWrappers", "Libdl", "Libglvnd_jll", "OpenSSL_jll", "Pkg", "Xorg_libXext_jll", "Xorg_libxcb_jll", "Xorg_xcb_util_image_jll", "Xorg_xcb_util_keysyms_jll", "Xorg_xcb_util_renderutil_jll", "Xorg_xcb_util_wm_jll", "Zlib_jll", "xkbcommon_jll"]
git-tree-sha1 = "c6c0f690d0cc7caddb74cef7aa847b824a16b256"
uuid = "ea2cea3b-5b76-57ae-a6ef-0a8af62496e1"
version = "5.15.3+1"

[[deps.QuadGK]]
deps = ["DataStructures", "LinearAlgebra"]
git-tree-sha1 = "78aadffb3efd2155af139781b8a8df1ef279ea39"
uuid = "1fd47b50-473d-5c70-9696-f719f8f3bcdc"
version = "2.4.2"

[[deps.Quaternions]]
deps = ["DualNumbers", "LinearAlgebra", "Random"]
git-tree-sha1 = "b327e4db3f2202a4efafe7569fcbe409106a1f75"
uuid = "94ee1d12-ae83-5a48-8b1c-48b8ff168ae0"
version = "0.5.6"

[[deps.REPL]]
deps = ["InteractiveUtils", "Markdown", "Sockets", "Unicode"]
uuid = "3fa0cd96-eef1-5676-8a61-b3b8758bbffb"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.Random123]]
deps = ["Random", "RandomNumbers"]
git-tree-sha1 = "7a1a306b72cfa60634f03a911405f4e64d1b718b"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.6.0"

[[deps.RandomNumbers]]
deps = ["Random", "Requires"]
git-tree-sha1 = "043da614cc7e95c703498a491e2c21f58a2b8111"
uuid = "e6cf234a-135c-5ec9-84dd-332b85af5143"
version = "1.5.3"

[[deps.RangeArrays]]
git-tree-sha1 = "b9039e93773ddcfc828f12aadf7115b4b4d225f5"
uuid = "b3c3ace0-ae52-54e7-9d0b-2c1406fd6b9d"
version = "0.3.2"

[[deps.Ratios]]
deps = ["Requires"]
git-tree-sha1 = "dc84268fe0e3335a62e315a3a7cf2afa7178a734"
uuid = "c84ed2f1-dad5-54f0-aa8e-dbefe2724439"
version = "0.4.3"

[[deps.RealDot]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "9f0a1b71baaf7650f4fa8a1d168c7fb6ee41f0c9"
uuid = "c1ae055f-0cd5-4b69-90a6-9a35b1a98df9"
version = "0.1.0"

[[deps.RecipesBase]]
git-tree-sha1 = "6bf3f380ff52ce0832ddd3a2a7b9538ed1bcca7d"
uuid = "3cdcf5f2-1ef4-517c-9805-6587b60abb01"
version = "1.2.1"

[[deps.RecipesPipeline]]
deps = ["Dates", "NaNMath", "PlotUtils", "RecipesBase"]
git-tree-sha1 = "e7eac76a958f8664f2718508435d058168c7953d"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.6.3"

[[deps.Reexport]]
git-tree-sha1 = "45e428421666073eab6f2da5c9d310d99bb12f9b"
uuid = "189a3867-3050-52da-a836-e630ba90ab69"
version = "1.2.2"

[[deps.RegionTrees]]
deps = ["IterTools", "LinearAlgebra", "StaticArrays"]
git-tree-sha1 = "4618ed0da7a251c7f92e869ae1a19c74a7d2a7f9"
uuid = "dee08c22-ab7f-5625-9660-a9af2021b33f"
version = "0.3.2"

[[deps.RelocatableFolders]]
deps = ["SHA", "Scratch"]
git-tree-sha1 = "22c5201127d7b243b9ee1de3b43c408879dff60f"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.3.0"

[[deps.Requires]]
deps = ["UUIDs"]
git-tree-sha1 = "838a3a4188e2ded87a4f9f184b4b0d78a1e91cb7"
uuid = "ae029012-a4dd-5104-9daa-d747884805df"
version = "1.3.0"

[[deps.Rmath]]
deps = ["Random", "Rmath_jll"]
git-tree-sha1 = "bf3188feca147ce108c76ad82c2792c57abe7b1f"
uuid = "79098fc4-a85e-5d69-aa6a-4863f24498fa"
version = "0.7.0"

[[deps.Rmath_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "68db32dff12bb6127bac73c209881191bf0efbb7"
uuid = "f50d1b31-88e8-58de-be2c-1cc44531875f"
version = "0.3.0+0"

[[deps.Rotations]]
deps = ["LinearAlgebra", "Quaternions", "Random", "StaticArrays", "Statistics"]
git-tree-sha1 = "3177100077c68060d63dd71aec209373c3ec339b"
uuid = "6038ab10-8711-5258-84ad-4b1120ba62dc"
version = "1.3.1"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"
version = "0.7.0"

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "f94f779c94e58bf9ea243e77a37e16d9de9126bd"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.1"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.Setfield]]
deps = ["ConstructionBase", "Future", "MacroTools", "StaticArraysCore"]
git-tree-sha1 = "e2cc6d8c88613c05e1defb55170bf5ff211fbeac"
uuid = "efcf1570-3423-57d1-acb7-fd33fddbac46"
version = "1.1.1"

[[deps.SharedArrays]]
deps = ["Distributed", "Mmap", "Random", "Serialization"]
uuid = "1a1011a3-84de-559e-8e89-a11a2f7dc383"

[[deps.ShowCases]]
git-tree-sha1 = "7f534ad62ab2bd48591bdeac81994ea8c445e4a5"
uuid = "605ecd9f-84a6-4c9e-81e2-4798472b76a3"
version = "0.1.0"

[[deps.Showoff]]
deps = ["Dates", "Grisu"]
git-tree-sha1 = "91eddf657aca81df9ae6ceb20b959ae5653ad1de"
uuid = "992d4aef-0814-514b-bc4d-f2e9a6c4116f"
version = "1.0.3"

[[deps.SimpleBufferStream]]
git-tree-sha1 = "874e8867b33a00e784c8a7e4b60afe9e037b74e1"
uuid = "777ac1f9-54b0-4bf8-805c-2214025038e7"
version = "1.1.0"

[[deps.SimpleTraits]]
deps = ["InteractiveUtils", "MacroTools"]
git-tree-sha1 = "5d7e3f4e11935503d3ecaf7186eac40602e7d231"
uuid = "699a6c99-e7fa-54fc-8d76-47d257e15c1d"
version = "0.9.4"

[[deps.SimpleWeightedGraphs]]
deps = ["Graphs", "LinearAlgebra", "Markdown", "SparseArrays", "Test"]
git-tree-sha1 = "a6f404cc44d3d3b28c793ec0eb59af709d827e4e"
uuid = "47aef6b3-ad0c-573a-a1e2-d07658019622"
version = "1.2.1"

[[deps.Sixel]]
deps = ["Dates", "FileIO", "ImageCore", "IndirectArrays", "OffsetArrays", "REPL", "libsixel_jll"]
git-tree-sha1 = "8fb59825be681d451c246a795117f317ecbcaa28"
uuid = "45858cf5-a6b0-47a3-bbea-62219f50df47"
version = "0.1.2"

[[deps.Sockets]]
uuid = "6462fe0b-24de-5631-8697-dd941f90decc"

[[deps.SortingAlgorithms]]
deps = ["DataStructures"]
git-tree-sha1 = "b3363d7460f7d098ca0912c69b082f75625d7508"
uuid = "a2af1166-a08f-5f64-846c-94a0d3cef48c"
version = "1.0.1"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.SpecialFunctions]]
deps = ["ChainRulesCore", "IrrationalConstants", "LogExpFunctions", "OpenLibm_jll", "OpenSpecFun_jll"]
git-tree-sha1 = "d75bda01f8c31ebb72df80a46c88b25d1c79c56d"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.7"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "f94f9d627ba3f91e41a815b9f9f977d729e2e06f"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.7.6"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "dfec37b90740e3b9aa5dc2613892a3fc155c3b42"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.6"

[[deps.StaticArraysCore]]
git-tree-sha1 = "ec2bd695e905a3c755b33026954b119ea17f2d22"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.3.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "f9af7f195fb13589dd2e2d57fdb401717d2eb1f6"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.5.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "d1bf48bfcc554a3761a133fe3a9bb01488e06916"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.21"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArraysCore", "Tables"]
git-tree-sha1 = "8c6ac65ec9ab781af05b08ff305ddc727c25f680"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.12"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"
version = "1.0.0"

[[deps.TableTraits]]
deps = ["IteratorInterfaceExtensions"]
git-tree-sha1 = "c06b2f539df1c6efa794486abfb6ed2022561a39"
uuid = "3783bdb8-4a98-5b6b-af9a-565f29a5fe9c"
version = "1.0.1"

[[deps.Tables]]
deps = ["DataAPI", "DataValueInterfaces", "IteratorInterfaceExtensions", "LinearAlgebra", "OrderedCollections", "TableTraits", "Test"]
git-tree-sha1 = "5ce79ce186cc678bbb5c5681ca3379d1ddae11a1"
uuid = "bd369af6-aec1-5ad0-b16a-f7cc5008161c"
version = "1.7.0"

[[deps.Tar]]
deps = ["ArgTools", "SHA"]
uuid = "a4e569a6-e804-4fa4-b0f3-eef7a1d5b13e"
version = "1.10.0"

[[deps.Tectonic]]
deps = ["Pkg"]
git-tree-sha1 = "0b3881685ddb3ab066159b2ce294dc54fcf3b9ee"
uuid = "9ac5f52a-99c6-489f-af81-462ef484790f"
version = "0.8.0"

[[deps.TensorCore]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "1feb45f88d133a655e001435632f019a9a1bcdb6"
uuid = "62fd8b95-f654-4bbd-a8a5-9c27f68ccd50"
version = "0.1.1"

[[deps.Test]]
deps = ["InteractiveUtils", "Logging", "Random", "Serialization"]
uuid = "8dfed614-e22c-5e08-85e1-65c5234f0b40"

[[deps.TiffImages]]
deps = ["ColorTypes", "DataStructures", "DocStringExtensions", "FileIO", "FixedPointNumbers", "IndirectArrays", "Inflate", "Mmap", "OffsetArrays", "PkgVersion", "ProgressMeter", "UUIDs"]
git-tree-sha1 = "70e6d2da9210371c927176cb7a56d41ef1260db7"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.1"

[[deps.TikzPictures]]
deps = ["LaTeXStrings", "Poppler_jll", "Requires", "Tectonic"]
git-tree-sha1 = "4e75374d207fefb21105074100034236fceed7cb"
uuid = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"
version = "3.4.2"

[[deps.TiledIteration]]
deps = ["OffsetArrays"]
git-tree-sha1 = "5683455224ba92ef59db72d10690690f4a8dc297"
uuid = "06e1c1a7-607b-532d-9fad-de7d9aa2abac"
version = "0.3.1"

[[deps.TimerOutputs]]
deps = ["ExprTools", "Printf"]
git-tree-sha1 = "9dfcb767e17b0849d6aaf85997c98a5aea292513"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.21"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "ed5d390c7addb70e90fd1eb783dcb9897922cbfa"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.8"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "e59ecc5a41b000fa94423a578d29290c7266fc10"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.4.0"

[[deps.UUIDs]]
deps = ["Random", "SHA"]
uuid = "cf7118a7-6976-5b1a-9a39-7adc72f591a4"

[[deps.UnPack]]
git-tree-sha1 = "387c1f73762231e86e0c9c5443ce3b4a0a9a0c2b"
uuid = "3a884ed6-31ef-47d7-9d2a-63182c4928ed"
version = "1.0.2"

[[deps.Unicode]]
uuid = "4ec0a83e-493e-50e2-b9ac-8f72acf5a8f5"

[[deps.UnicodeFun]]
deps = ["REPL"]
git-tree-sha1 = "53915e50200959667e78a92a418594b428dffddf"
uuid = "1cfade01-22cf-5700-b092-accc4b62d6e1"
version = "0.4.1"

[[deps.Unzip]]
git-tree-sha1 = "34db80951901073501137bdbc3d5a8e7bbd06670"
uuid = "41fe7b60-77ed-43a1-b4f0-825fd5a5650d"
version = "0.1.2"

[[deps.Wayland_jll]]
deps = ["Artifacts", "Expat_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "3e61f0b86f90dacb0bc0e73a0c5a83f6a8636e23"
uuid = "a2964d1f-97da-50d4-b82a-358c7fce9d89"
version = "1.19.0+0"

[[deps.Wayland_protocols_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4528479aa01ee1b3b4cd0e6faef0e04cf16466da"
uuid = "2381bf8a-dfd0-557d-9999-79630e7b1b91"
version = "1.25.0+0"

[[deps.WoodburyMatrices]]
deps = ["LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "de67fa59e33ad156a590055375a30b23c40299d3"
uuid = "efce3f68-66dc-5838-9240-27a6d6f5f9b6"
version = "0.5.5"

[[deps.XML2_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "Zlib_jll"]
git-tree-sha1 = "58443b63fb7e465a8a7210828c91c08b92132dff"
uuid = "02c8fc9c-b97f-50b9-bbe4-9be30ff0a78a"
version = "2.9.14+0"

[[deps.XSLT_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libgcrypt_jll", "Libgpg_error_jll", "Libiconv_jll", "Pkg", "XML2_jll", "Zlib_jll"]
git-tree-sha1 = "91844873c4085240b95e795f692c4cec4d805f8a"
uuid = "aed1982a-8fda-507f-9586-7b0439959a61"
version = "1.1.34+0"

[[deps.Xorg_libX11_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll", "Xorg_xtrans_jll"]
git-tree-sha1 = "5be649d550f3f4b95308bf0183b82e2582876527"
uuid = "4f6342f7-b3d2-589e-9d20-edeb45f2b2bc"
version = "1.6.9+4"

[[deps.Xorg_libXau_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4e490d5c960c314f33885790ed410ff3a94ce67e"
uuid = "0c0b7dd1-d40b-584c-a123-a41640f87eec"
version = "1.0.9+4"

[[deps.Xorg_libXcursor_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXfixes_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "12e0eb3bc634fa2080c1c37fccf56f7c22989afd"
uuid = "935fb764-8cf2-53bf-bb30-45bb1f8bf724"
version = "1.2.0+4"

[[deps.Xorg_libXdmcp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fe47bd2247248125c428978740e18a681372dd4"
uuid = "a3789734-cfe1-5b06-b2d0-1dd0d9d62d05"
version = "1.1.3+4"

[[deps.Xorg_libXext_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "b7c0aa8c376b31e4852b360222848637f481f8c3"
uuid = "1082639a-0dae-5f34-9b06-72781eeb8cb3"
version = "1.3.4+4"

[[deps.Xorg_libXfixes_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "0e0dc7431e7a0587559f9294aeec269471c991a4"
uuid = "d091e8ba-531a-589c-9de9-94069b037ed8"
version = "5.0.3+4"

[[deps.Xorg_libXi_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXfixes_jll"]
git-tree-sha1 = "89b52bc2160aadc84d707093930ef0bffa641246"
uuid = "a51aa0fd-4e3c-5386-b890-e753decda492"
version = "1.7.10+4"

[[deps.Xorg_libXinerama_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll"]
git-tree-sha1 = "26be8b1c342929259317d8b9f7b53bf2bb73b123"
uuid = "d1454406-59df-5ea1-beac-c340f2130bc3"
version = "1.1.4+4"

[[deps.Xorg_libXrandr_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libXext_jll", "Xorg_libXrender_jll"]
git-tree-sha1 = "34cea83cb726fb58f325887bf0612c6b3fb17631"
uuid = "ec84b674-ba8e-5d96-8ba1-2a689ba10484"
version = "1.5.2+4"

[[deps.Xorg_libXrender_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "19560f30fd49f4d4efbe7002a1037f8c43d43b96"
uuid = "ea2f1a96-1ddc-540d-b46f-429655e07cfa"
version = "0.9.10+4"

[[deps.Xorg_libpthread_stubs_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "6783737e45d3c59a4a4c4091f5f88cdcf0908cbb"
uuid = "14d82f49-176c-5ed1-bb49-ad3f5cbd8c74"
version = "0.1.0+3"

[[deps.Xorg_libxcb_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "XSLT_jll", "Xorg_libXau_jll", "Xorg_libXdmcp_jll", "Xorg_libpthread_stubs_jll"]
git-tree-sha1 = "daf17f441228e7a3833846cd048892861cff16d6"
uuid = "c7cfdc94-dc32-55de-ac96-5a1b8d977c5b"
version = "1.13.0+3"

[[deps.Xorg_libxkbfile_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libX11_jll"]
git-tree-sha1 = "926af861744212db0eb001d9e40b5d16292080b2"
uuid = "cc61e674-0454-545c-8b26-ed2c68acab7a"
version = "1.1.0+4"

[[deps.Xorg_xcb_util_image_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "0fab0a40349ba1cba2c1da699243396ff8e94b97"
uuid = "12413925-8142-5f55-bb0e-6d7ca50bb09b"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxcb_jll"]
git-tree-sha1 = "e7fd7b2881fa2eaa72717420894d3938177862d1"
uuid = "2def613f-5ad1-5310-b15b-b15d46f528f5"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_keysyms_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "d1151e2c45a544f32441a567d1690e701ec89b00"
uuid = "975044d2-76e6-5fbe-bf08-97ce7c6574c7"
version = "0.4.0+1"

[[deps.Xorg_xcb_util_renderutil_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "dfd7a8f38d4613b6a575253b3174dd991ca6183e"
uuid = "0d47668e-0667-5a69-a72c-f761630bfb7e"
version = "0.3.9+1"

[[deps.Xorg_xcb_util_wm_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xcb_util_jll"]
git-tree-sha1 = "e78d10aab01a4a154142c5006ed44fd9e8e31b67"
uuid = "c22f9ab0-d5fe-5066-847c-f4bb1cd4e361"
version = "0.4.1+1"

[[deps.Xorg_xkbcomp_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_libxkbfile_jll"]
git-tree-sha1 = "4bcbf660f6c2e714f87e960a171b119d06ee163b"
uuid = "35661453-b289-5fab-8a00-3d9160c6a3a4"
version = "1.4.2+4"

[[deps.Xorg_xkeyboard_config_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Xorg_xkbcomp_jll"]
git-tree-sha1 = "5c8424f8a67c3f2209646d4425f3d415fee5931d"
uuid = "33bec58e-1273-512f-9401-5d533626f822"
version = "2.27.0+4"

[[deps.Xorg_xtrans_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "79c31e7844f6ecf779705fbc12146eb190b7d845"
uuid = "c5fb5394-a638-5e4d-96e5-b29de1b5cf10"
version = "1.4.0+3"

[[deps.Zlib_jll]]
deps = ["Libdl"]
uuid = "83775a58-1f1d-513f-b197-d71354ab007a"
version = "1.2.12+3"

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "GPUArrays", "GPUArraysCore", "IRTools", "InteractiveUtils", "LinearAlgebra", "LogExpFunctions", "MacroTools", "NaNMath", "Random", "Requires", "SparseArrays", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "b02f2f7feda60d40aa7c24291ee865b50b33c9bc"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.45"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.libaom_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "3a2ea60308f0996d26f1e5354e10c24e9ef905d4"
uuid = "a4ae2306-e953-59d6-aa16-d00cac43593b"
version = "3.4.0+0"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
version = "5.1.1+0"

[[deps.libfdk_aac_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "daacc84a041563f965be61859a36e17c4e4fcd55"
uuid = "f638f0a6-7fb0-5443-88ba-1cc74229b280"
version = "2.0.2+0"

[[deps.libpng_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "94d180a6d2b5e55e447e2d27a29ed04fe79eb30c"
uuid = "b53b4c65-9356-5827-b1ea-8c7a1a84506f"
version = "1.6.38+0"

[[deps.libsixel_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "78736dab31ae7a53540a6b752efc61f77b304c5b"
uuid = "075b6546-f08a-558a-be8f-8157d0f608a5"
version = "1.8.6+1"

[[deps.libvorbis_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Ogg_jll", "Pkg"]
git-tree-sha1 = "b910cb81ef3fe6e78bf6acee440bda86fd6ae00c"
uuid = "f27f6e37-5d2b-51aa-960f-b287f2bc3b7a"
version = "1.3.7+1"

[[deps.nghttp2_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "8e850ede-7688-5339-a07c-302acd2aaf8d"
version = "1.48.0+0"

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"
version = "17.4.0+0"

[[deps.x264_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "4fea590b89e6ec504593146bf8b988b2c00922b2"
uuid = "1270edf5-f2f9-52d2-97e9-ab00b5d0237a"
version = "2021.5.5+0"

[[deps.x265_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "ee567a171cce03570d77ad3a43e90218e38937a9"
uuid = "dfaa095f-4041-5dcd-9319-2fabd8486b76"
version = "3.5.0+0"

[[deps.xkbcommon_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg", "Wayland_jll", "Wayland_protocols_jll", "Xorg_libxcb_jll", "Xorg_xkeyboard_config_jll"]
git-tree-sha1 = "9ebfc140cc56e8c2156a15ceac2f0302e327ac0a"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "1.4.1+0"
"""

# ╔═╡ Cell order:
# ╟─1dbd6f48-d07c-428d-9dad-3bbbf80a73c4
# ╟─0cd10bf9-c31e-4f86-833a-f6f64b951015
# ╠═9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╟─6cf9db2d-f16d-4e4e-a1e4-915d37a2705f
# ╟─8aa02b43-9c28-4d7e-8eac-551b1e8a4e76
# ╟─5e9486a3-5518-44ad-a9f2-d5371092e46f
# ╟─e716f94c-1f4a-4616-bc65-c1e48723bfe3
# ╟─954276ad-e5b9-43c2-a969-30410829e778
# ╟─a8a40434-4b36-411c-b364-a1056b8295a5
# ╟─dc635c3b-3bd5-4542-9970-69acb3bfc207
# ╟─d6c80374-a253-4943-98fb-977c6deefa1d
# ╟─d487df8f-dc41-4f00-be4e-9d5c4b97e7a4
# ╟─ee2daf54-7a9e-4e31-a015-610479671424
# ╟─3f003028-ece9-41e6-98c0-3c03652ef3af
# ╟─25bd7d39-cb39-4bab-879f-54ed98169b34
# ╟─f908c4ab-3f9c-4f64-89a5-b046d9dba4cc
# ╟─eab0af69-82ba-43f1-bc40-7fddfe7b2e12
# ╟─3ff8833b-e8d8-4621-b062-d3065de91ba6
# ╟─c820e809-5d03-4073-8326-1fe782decb44
# ╟─5b6d013f-2d8c-4919-8fe4-4af5219c3634
# ╟─5cb8738a-7c85-4c88-984e-5a86fcd7acd5
# ╟─04e00283-05c2-4b1b-8c44-54fb1dddb124
# ╟─ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
# ╟─ad1a47b9-d9d3-4f39-ad8e-7749c651da12
# ╟─f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
# ╟─4c661db2-312a-4e03-8f66-df2bb68ad9a7
# ╟─52ca4280-f092-4941-aed5-e3fc25b3149a
# ╟─88ba9bb1-02b3-4f32-bf6c-be8f99626f13
# ╟─9dee8b4a-451c-4714-8257-9a47b2133002
# ╟─ea2faddf-38b2-46ab-9a53-2057ade1f198
# ╟─5f023b91-b0ae-4e91-94fb-f56312c8135f
# ╟─c06b600f-3a79-416e-b2d8-3d85c571d2c8
# ╟─155ee558-8b6f-446b-adbe-41355e9745c0
# ╟─0f9a59ac-4a82-4bbd-b662-344491304c53
# ╟─3dfd513a-d8c0-4e04-aa57-02ee1a63367e
# ╟─bf2619d5-8f84-4340-9e6f-8343d687fc03
# ╟─97a8e5d2-85e3-428c-99f0-5348324ea5c6
# ╟─3e268142-8c00-423f-ab45-abb37e904bb2
# ╟─296fc611-5d26-44c4-8df8-209401a8582a
# ╟─7c7a76b5-ff7e-4731-96f4-49100d59e03a
# ╟─c9cef05b-944b-4595-863d-a0312973d5a3
# ╟─b7477763-33b6-4506-a253-f0700472788d
# ╟─cd4f2546-fe46-42db-8197-7278ccd32cbe
# ╟─fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
# ╟─1484d096-0beb-44d7-8192-6948f3ccd7ca
# ╟─81011ca8-c063-4ee4-8aaa-1a5021504ad0
# ╟─953701fe-c67a-498f-bf83-a50a6b45e38d
# ╟─33a8bfd4-c5c6-42a0-add7-334e153f1785
# ╟─33523f7c-974e-45d1-968b-63c80bca6cdf
# ╟─635380fc-59aa-4d62-ab0a-4c8f2e1ec3df
# ╟─371a446e-22e3-4607-a6f5-f72d586e4ef6
# ╟─5cf53359-3e33-4b8e-91ff-4dac4139f315
# ╟─da2931b6-4c0b-43cf-882f-328f67f963b2
# ╟─6a322541-4a04-4201-8117-4079e8e5ca2c
# ╟─86c31ee6-2b45-46c0-99ef-8e8da7c67717
# ╟─53bd8687-a7bb-43b6-b4b1-f487c9fa40af
# ╟─9d28cfad-1ee4-4946-9090-6d06ed985761
# ╠═b5b1322b-bd82-4f25-b888-7dbefd8fb1e0
# ╟─cdffe713-0b1d-45cf-b5d3-ea5b86882986
# ╠═25f0cc4d-f659-44f3-8319-e9a12f8c563a
# ╠═003ba2de-5aee-4c7d-9af6-2472f714e483
# ╠═5ce19f81-2205-4fc2-88dc-ff8e3c50c28e
# ╟─7d2e7333-eded-4168-9364-0b7b63f5acd3
# ╠═ef88fae7-1baf-44bc-8405-20acdb9301a0
# ╟─b42d417d-aa67-4988-8c4a-dd105d0353f8
# ╟─4633febc-b1ce-43a6-8f3a-854e29c56beb
# ╠═28437714-35d6-47dd-8609-441fa0a68eda
# ╟─3614c791-ce6d-41f2-94ae-ed01cf15fbae
# ╠═bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
# ╟─a58364b1-debb-4c5d-9f69-6dadb2a57ffa
# ╠═458ab7d6-45dc-43d4-85ed-8ea355aca06d
# ╟─67081a13-78fd-485a-89c5-0ca04479a76a
# ╠═4435ed2f-718b-444e-8c2b-a7c04cde8ad8
# ╟─444b6d1f-030e-4c8d-a74d-2ffbf5022649
# ╟─b910aefc-822a-4adc-81e1-b08673729e0c
# ╟─9f52266e-3ad3-4823-a1ab-dd08294136d6
# ╠═04ca9af8-d29b-4694-af98-fce02036023f
# ╟─953213c6-4726-400d-adf0-8e36defe1ce4
# ╠═bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
# ╟─0ca87da2-bb36-4c75-bf59-fe2cfe73edd4
# ╠═f717b0a9-83a3-400b-8093-80fb6561514f
# ╟─bc883d10-c074-4e55-8848-892e7f512556
# ╟─eaa3491f-3dec-465a-9a8a-96d43cc8c4e8
# ╠═4107ded4-4e57-4f22-ad50-83735f7a97ff
# ╠═be133738-eeea-4db2-90d4-47266bf80a65
# ╟─4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
# ╟─08b3bac8-e3f3-46eb-b147-683bc540dd81
# ╟─53665dae-662d-4121-b08a-d477fab2578a
# ╟─3e384580-500c-4b26-b5ab-d0ec84e1eb40
# ╠═d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
# ╠═5cb477cd-e20c-4006-90b1-8d43a1fa1ce6
# ╠═0671f818-b38e-4ae0-9cc7-fb82244394ac
# ╠═7ebf4038-c827-40de-b1ac-7145a6a297f7
# ╟─f0220f84-07f7-452f-a975-6f08f27a6d0b
# ╟─e9245c18-1fac-49f5-9f68-a46b8e4c0fc9
# ╠═4cc3ae85-028c-4952-9ad8-94063cee74ae
# ╟─ba00f149-c675-4dfb-97fb-483df8fa761d
# ╟─28eec921-d948-4ace-b0a0-1a35b6f464d7
# ╟─53521e21-7040-493e-802a-cf75cb4c0f65
# ╟─d5746b74-f170-45ac-ad93-be3e9d32f3a0
# ╟─1cf291f1-7a8a-4573-891d-ab84162e0895
# ╟─5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
# ╟─e42a5c8f-5511-46e1-9495-8fc198fae087
# ╠═c1763137-a746-4fc8-b0c7-a4da50105926
# ╠═20ee48a9-7991-43d1-9ade-d1b7f89ebb4e
# ╟─7ad675e8-bbe7-41a8-ad53-decdb8267097
# ╟─8010bd8a-5f63-4ee8-8f23-34b59c0297e4
# ╟─1b17fd8f-008e-4064-a866-332071647796
# ╟─910f89b9-64dd-480b-b6d7-19f8eb61923d
# ╟─c6bac43b-dfab-49f8-ae6c-4d33b8b55663
# ╟─5a6759db-ad6c-48ac-aff3-266b76c9b715
# ╟─953523a6-fa73-46ca-a59d-11bd818f8a11
# ╟─ee6a4ba8-1342-448a-999d-aa063e883654
# ╠═28043665-f5fa-4ebc-8388-9a378ce1e894
# ╠═71147b63-5c89-4296-b1a5-e9da2eeeb73e
# ╠═d11d4529-1c0c-4a15-8566-7ef4d86d4c57
# ╠═51dcdae9-290b-4c08-be04-071c044ae9e4
# ╠═18dcd447-695f-4c14-b646-5c6b24d961ce
# ╠═8b182c60-18f2-413e-b077-eb1c39090fb5
# ╟─5eeef94f-5bd3-4165-878b-1b4a66ab71a8
# ╟─832fa40e-e4ef-42fb-bc25-133d19a5c579
# ╟─2016349b-cfd5-40ef-bfdd-835db6e0f6fe
# ╟─2eb47163-e8dd-4307-8dff-454cabf81d90
# ╟─f1425013-66af-44a9-aada-7101251ef0b9
# ╟─c45c5d71-933e-4c1b-bf62-a982ed736ed8
# ╟─5cc13399-73e9-4717-93cc-fe73f11bccc9
# ╟─f25e58ac-ae39-4c46-9328-5eb5656b37ea
# ╟─18657b2f-108e-4f11-ae34-3d889e10e76d
# ╟─b042bd90-8b5e-4556-b8a9-542e35cdb6de
# ╟─5f5733a5-2bb4-4045-8671-f3dc7b0586fb
# ╟─d37939ad-4937-46f9-a5f7-5394a8c38ded
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
