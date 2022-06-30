### A Pluto.jl notebook ###
# v0.19.9

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
begin
	using Distributions
	using Flux
	using GLPK
	using Graphs
	using GridGraphs
	using InferOpt
	using Images
	using JuMP
	using LinearAlgebra
	using Plots
	using PlutoUI
	using ProgressMeter
	using Random
	using SparseArrays
	using Statistics
	using TikzPictures
end

# ╔═╡ 0617b570-c163-4bd6-8a6b-e49653c1af7f
TableOfContents(depth=1)

# ╔═╡ e716f94c-1f4a-4616-bc65-c1e48723bfe3
begin
	fig = TikzPicture(L"""
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
	""", options="scale=1");
	fig2 = TikzPicture(L"""
	\tikzset{node/.style={fill=red!10, shape=rectangle, draw=black, minimum width=100, minimum height=40, font=\LARGE, line width=1.5}}
	\node[node] (t) at (0, 0) {$t$};
	\node[node] (u) at (7, 0) {$u$};
	\node[] (time1) at (-2, -1) {};
	\node[] (time2) at (9, -1) {};
	\draw[<->, line width=1.5] (t) edge node[below]{slack $\Delta_{u,t}$} (u);
	\draw[->, line width=1.5] (time1) edge node[below, pos=0.95]{time} (time2);
	""", options="scale=1");
end;

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

# ╔═╡ 62ccfefa-9c5e-4b8f-94e0-8d17b54438da
TwoColumn(md"Hello", md"Goodbye", 70, 30)

# ╔═╡ eab0af69-82ba-43f1-bc40-7fddfe7b2e12
md"""
# InferOpt.jl: combinatorial optimization in machine learning pipelines

**[Guillaume Dalle](https://gdalle.github.io/), [Léo Baty](https://batyleo.github.io/), [Louis Bouvier](https://louisbouvier.github.io/) and [Axel Parmentier](https://cermics.enpc.fr/~parmenta/)**

CERMICS, École des Ponts
"""

# ╔═╡ 3ff8833b-e8d8-4621-b062-d3065de91ba6
md"""
> Add photos
"""

# ╔═╡ c820e809-5d03-4073-8326-1fe782decb44
html"<button onclick='present()'>Toggle presentation mode</button>"

# ╔═╡ 5b6d013f-2d8c-4919-8fe4-4af5219c3634
md"""
# 1. What is it for ?
"""

# ╔═╡ 5cb8738a-7c85-4c88-984e-5a86fcd7acd5
md"""
- Enrich learning pipelines with combinatorial algorithms
- Enhance combinatorial algorithms with learning pipelines
"""

# ╔═╡ afc55865-b3f2-4f39-8c00-2c38957f0289
md"""
## Package overview

InferOpt.jl gathers several state-of-the-art methods at the intersection between Combinatorial Optimization (CO) and Machine Learning (ML).

```math
\xrightarrow[\text{instance}]{\text{Initial}}
\fbox{ML predictor}
\xrightarrow[\text{instance}]{\text{Encoded}}
\fbox{CO algorithm}
\xrightarrow[\text{solution}]{\text{Candidate}}
\text{Loss}
```

**Two learning settings:**
- Learning by imitation
- Learning by experience

**Theoretical challenge:** Differentiating through CO algorithms
"""

# ╔═╡ 04e00283-05c2-4b1b-8c44-54fb1dddb124
md"""
## Many possible applications

- Shortest paths on Warcraft maps $\impliedby$ **today**
- Stochastic Vehicle Scheduling $\impliedby$ **today**
- Two-stage Minimum Spanning Tree
- Single-machine scheduling
- Multi-Agent PathFinding
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

# ╔═╡ e1badec7-4b93-4308-9356-16577e398fe9
md"""
## A glimpse at the dataset (1)
"""

# ╔═╡ fcb144ba-5477-49da-a32c-232545f7511b
begin
	image_label1 = load("./images/image_label1.png")
	plot(image_label1, ticks = nothing, border = nothing)
end

# ╔═╡ c6bf44df-f4a3-4fda-8aa8-d565849acdde
md"""
## A glimpse at the dataset (2)
"""

# ╔═╡ ad1a47b9-d9d3-4f39-ad8e-7749c651da12
begin
	image_label2 = load("./images/image_label2.png")
	plot(image_label2, ticks = nothing, border = nothing)
end

# ╔═╡ f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
md"""
## ML-CO pipeline
"""

# ╔═╡ 4c661db2-312a-4e03-8f66-df2bb68ad9a7
begin
	warcraftpipeline = load("./images/warcraft_pipeline.png")
	plot(warcraftpipeline, ticks = nothing, border = nothing)
end

# ╔═╡ d32c406d-f3d2-450d-a42d-d1ccab1b66b0
md"""
## Training metrics

Small sub-dataset: 80 maps in the train set, 20 in the test set
"""

# ╔═╡ 1a1e818a-d774-417e-bd5c-18f88e116635
begin
	image_lossgap = load("./images/lossgap.png")
	plot(image_lossgap, ticks = nothing, border = nothing)
end

# ╔═╡ 52ca4280-f092-4941-aed5-e3fc25b3149a
md"""
## Test set prediction (1)

We can compare the predicted costs $\theta = \varphi_w(x)$ and the true costs on samples from the test set.
"""

# ╔═╡ 88ba9bb1-02b3-4f32-bf6c-be8f99626f13
begin 
	weights1 = load("./images/weights1.png")
	plot(weights1, ticks = nothing, border = nothing)
end

# ╔═╡ f2df0373-b253-4abf-9719-462512ab029f
md"""
## Test set prediction (2)

We can also compare the predicted shortest path with the theoretical one.
"""

# ╔═╡ ea2faddf-38b2-46ab-9a53-2057ade1f198
begin 
	img_path_label1 = load("./images/image_path_label1.png")
	plot(img_path_label1, ticks = nothing, border = nothing)
end

# ╔═╡ 06c9d007-7fe8-489d-baa9-7264f83cc0d0
md"""
## Test set results (3)

Another example: 
"""

# ╔═╡ 77423e24-7eca-4352-8ee3-0fa7b6e4b687
begin 
	weights2 = load("./images/weights2.png")
	plot(weights2, ticks = nothing, border = nothing)
end

# ╔═╡ 7a6a9c59-df26-4f81-b0b1-77ee99d98810
md"""
## Test set results (4)
"""

# ╔═╡ 916ff5c3-dbec-417b-a6eb-d99c7df7fc8b
begin 
	img_path_label2 = load("./images/image_path_label2.png")
	plot(img_path_label2, ticks = nothing, border = nothing)
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
- **Decision variables**: schedule of vehicle tours
- **Constraint**: all tasks must be fulfilled by exactly one vehicle
"""

# ╔═╡ 73f9d834-82d6-472c-8c66-ea85005c9287
md"""
> If you want to put the Tikz on every slide, make it smaller and put it on the side
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

# ╔═╡ f62f7d6f-a0f8-4dd4-806c-549f6773b020
md"""
> Do we really need the notations?
"""

# ╔═╡ bf2619d5-8f84-4340-9e6f-8343d687fc03
md"""
## MILP formulation

```math
(H)\left\{
\begin{aligned}
\min_y &\quad c^{veh} \sum_{a\in\delta^+(o)} y_a + \frac{1}{|S|}\sum_{s\in S}\sum_{t\in T} d_t^s \\
\text{s.t.} & \sum_{a\in\delta^-(t)}y_a = \sum_{a\in\delta^+(t)}y_a,\quad & \forall t\in T\\
& \sum_{a\in\delta^+(t)}y_a = 1, & \forall t\in T\\
& d_t^s \geq \varepsilon_t^s, & \forall t\in T,\,\forall s\in S\\
& d_t^s \geq \varepsilon_t^s + \sum_{a=(u, t)\in\delta^-(t)}(d_u^s-\Delta_{u,t}^s)y_a, & \forall t\in T,\,\forall s\in S\\
& y_a\in \{0, 1\}, & \forall a\in A\\
& d_t^s\in \mathbb{R}, & \forall t\in T,\,\forall s\in S
\end{aligned}
\right.
```

``\implies`` does not scale well with number of tasks and scenarios

Other option: column generation, but not enough
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
& \sum_{a\in\delta^+(t)}y_a = 1, & \forall t\in T\\
& y_a\in \{0, 1\}, & \forall a\in A
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
\fbox{Features $\phi(a, x)$}
\xrightarrow[]{\phi\in \mathbb{R}^{k\times d(x)}}
\fbox{GLM $\phi \mapsto w^\top \phi$}
\xrightarrow[\theta \in \mathbb{R}^{d(x)}]{\text{Cost vector}}
\fbox{Optimizer}
\xrightarrow[y \in \mathcal{Y}(x)]{\text{Solution}}
```

Features:
- Quantiles of the delay
- Vehicle cost

Machine learning predictor:
- ``\theta_a = w^T \phi(a, x)``
- learnable weights ``w``
"""

# ╔═╡ 36bd5f9b-1354-440a-b6b1-238f0f0def5e
md"""
> Don't use $\phi$, cause $\varphi$ usually stands for the predictor
"""

# ╔═╡ b7477763-33b6-4506-a253-f0700472788d
md"""
## ML-CO pipeline: illustration
"""

# ╔═╡ cb51241e-e327-4a3e-906b-47a3d51b1771
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
\draw[nopath, color=red] (v2) edge node[font=\LARGE, color=red, above]{$\theta_{2, 6} = w^\top \phi((2, 6), x)$} (v6);
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

# ╔═╡ cd4f2546-fe46-42db-8197-7278ccd32cbe
md"""
> Add results
"""

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
\fbox{Neural network $\varphi_w$}
\xrightarrow[\text{direction $\theta$}]{\text{Objective}}
\fbox{Linear optimizer $\underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$}
\xrightarrow[\text{solution $\widehat{y}$}]{\text{Candidate}}
\fbox{Loss}
```

The function $\theta \mapsto \underset{y \in \mathcal{Y}}{\mathrm{argmax}} ~ \theta^\top y$ is piecewise constant $\implies$ no gradient information.

Given a convex function $\Omega$, the regularized optimizer is defined by:

```math
\hat{y}_\Omega(\theta) = \underset{y \in \mathrm{conv}(\mathcal{Y})}{\mathrm{argmax}} \{\theta^\top y - \Omega(y)\} 
```
"""

# ╔═╡ 90c505c4-bd2d-4e95-96fd-1385672d2558
md"""
> Find a way to go the next line in `\fbox`
"""

# ╔═╡ 60e0f981-8eb6-4d5e-b38a-a973cf40be3a
begin
	one_hot_argmax(θ) = Float64.(1:length(θ) .== argmax(θ));
	soft_argmax(θ; s=1) = exp.(s * θ) ./ sum(exp, s * θ);
	e₁ = [1., 0., 0.]
	e₂ = [0., 1., 0.]
	e₃ = [0., 0., 1.]
	f₁ = e₁ + e₂ + e₃
	f₁ ./= norm(f₁)
	f₂ = e₁ - (e₁'f₁) * f₁
	f₂ ./= norm(f₂)
	f₃ = e₂ - (e₂'f₁) * f₁ - (e₂'f₂) * f₂
	f₃ ./= norm(f₃)
	project2d(x) = [dot(x, f₂), dot(x, f₃)]
	y₁, y₂, y₃ = map(project2d, (e₁, e₂, e₃))
	
	function plot_argmax(α; legend=true)
		θ = 0.35 * (cos(α) * f₂ + sin(α) * f₃)
		ŷ = one_hot_argmax(θ)
		ŷΩ = soft_argmax(θ; s=3.5)
	
		θ_2d = project2d(θ)
		ŷ_2d = project2d(ŷ)
		ŷΩ_2d = project2d(ŷΩ)
	
		λ₁ = dot(ŷΩ, e₁)
		λ₂ = dot(ŷΩ, e₂)
		λ₃ = dot(ŷΩ, e₃)
		
		pl = Plots.plot(; xlim=(-1, 1), ylim=(-1, 1), aspect_ratio=:equal, legend=legend)
		plot!(
			pl,
			[y₁[1], y₂[1], y₃[1], y₁[1]],
			[y₁[2], y₂[2], y₃[2], y₁[2]];
			fill=(0, :lightgray),
			linestyle=:dash,
			linecolor=:black,
			label="simplex Δ³"
		)
		plot!(
			pl,
			[0., θ_2d[1]],
			[0., θ_2d[2]],
			color=:black,
			arrow=true,
			lw=2,
			label="objective θ"
		)
		
		scatter!(
			pl,
			[ŷΩ_2d[1]],
			[ŷΩ_2d[2]];
			color=:blue,
			markersize=5,
			label="regularized argmax"
		)
		scatter!(
			pl,
			[y₁[1], y₂[1], y₃[1]],
			[y₁[2], y₂[2], y₃[2]];
			markersize=20 .* ([λ₁, λ₂, λ₃]).^0.7,
			markercolor=:blue,
			markerstrokewidth=0,
			markeralpha=0.4,
			label=nothing
		)
		scatter!(
			pl,
			[ŷ_2d[1]],
			[ŷ_2d[2]];
			color=:red,
			markersize=5,
			markershape=:square,
			label="hard argmax"
		)
		pl
	end
end;

# ╔═╡ 3b1bffd7-de24-405c-ae09-40223bc0b76d
@bind α Slider(0:0.01:2π; default=π)

# ╔═╡ d5e45cdf-7955-46fb-ab23-07f57a37fccc
plot_argmax(α)

# ╔═╡ 455a316f-ddc4-4eb0-b185-ed8dd5ff1589
md"""
> I'm gonna make a more complex polytope, stay tuned
"""

# ╔═╡ 9f293911-323f-4c91-926b-cff0927c16a1
md"""
## Fenchel-Young loss

Natural non-negative & convex loss based on regularization:

```math
\mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}) = \Omega^*(\theta) + \Omega(y) - \theta^\top y
```

Given a target solution $\bar{y}$ and a parameter $\theta$, a subgradient is given by:

```math
\widehat{y}_{\Omega}(\theta) - \bar{y} \in \partial_\theta \mathcal{L}_{\Omega}^{\text{FY}}(\theta, \bar{y}).
```


The optimization block has meaningful gradients $\implies$ we can backpropagate in the whole pipeline.
"""

# ╔═╡ 86c31ee6-2b45-46c0-99ef-8e8da7c67717
md"""
# 3. Tutorial
"""

# ╔═╡ 53bd8687-a7bb-43b6-b4b1-f487c9fa40af
md"""
## Problem statement

Let us imagine that we observe the itineraries chosen by a public transport user in several different networks, and that we want to understand their decision-making process (a.k.a. recover their utility function).

More precisely, each point in our dataset consists in:
- a graph ``G``
- a shortest path ``P`` from the top left to the bottom right corner

We don't know the true costs that were used to compute the shortest path, but we can exploit a set of features to approximate these costs.
The question is: how should we combine these features?

We will use `InferOpt` to learn the appropriate weights, so that we may propose relevant paths to the user in the future.
"""

# ╔═╡ 9d28cfad-1ee4-4946-9090-6d06ed985761
md"""
## GridGraphs

- We consider grid graphs, as implemented in [https://github.com/gdalle/GridGraphs.jl](https://github.com/gdalle/GridGraphs.jl).
- Each vertex corresponds to a couple of coordinates ``(i, j)``, where ``1 \leq i \leq h`` and ``1 \leq j \leq w``.
- We only allow the user to move right, down or both $\implies$ ensures acyclicity
- The cost of a move is defined as the cost of the arrival vertex

``\implies`` any grid graph is entirely characterized by its cost matrix ``\theta \in \mathbb{R}^{h \times w}``.
"""

# ╔═╡ 0f275285-a5be-4c97-862d-71193e9ac444
h, w = 50, 100;

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
p = path_to_matrix(g, grid_topological_sort(g, 1, nv(g)));

# ╔═╡ b42d417d-aa67-4988-8c4a-dd105d0353f8
spy(sparse(p))

# ╔═╡ 4633febc-b1ce-43a6-8f3a-854e29c56beb
md"""
## Input data

- We don't know the cost of each vertex.
- We have have access to a set of relevant features.
"""

# ╔═╡ 3614c791-ce6d-41f2-94ae-ed01cf15fbae
md"""
Generate random instances
"""

# ╔═╡ 28437714-35d6-47dd-8609-441fa0a68eda
nb_features = 10;

# ╔═╡ 6aac7a6a-14e3-4f36-ab18-f232a31813f4
nb_instances = 30;

# ╔═╡ bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
X_train = [randn(nb_features, h, w) for n in 1:nb_instances];

# ╔═╡ c8c4cfaa-1890-4ee0-8778-fed5cf188892
dropfirstdim(z::AbstractArray) = dropdims(z; dims=1)

# ╔═╡ a58364b1-debb-4c5d-9f69-6dadb2a57ffa
md"""
Let us assume that the user combines them using a shallow (linear) neural network.
"""

# ╔═╡ 458ab7d6-45dc-43d4-85ed-8ea355aca06d
true_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ 67081a13-78fd-485a-89c5-0ca04479a76a
md"""
Compute true (unknown) vertex costs
"""

# ╔═╡ 4435ed2f-718b-444e-8c2b-a7c04cde8ad8
θ_train = [true_encoder(x) for x in X_train];

# ╔═╡ 9f52266e-3ad3-4823-a1ab-dd08294136d6
md"""
The true vertex costs computed from this encoding are then used within longest path computations:

```math
\arg\max_{y\in \{0, 1\}^{h\times w}} \theta^T y
```
"""

# ╔═╡ 04ca9af8-d29b-4694-af98-fce02036023f
function linear_maximizer(θ; instance=nothing)
    g = AcyclicGridGraph(-θ)
    path = grid_topological_sort(g, 1, nv(g))
    return path_to_matrix(g, path)
end;

# ╔═╡ bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
Y_train = [linear_maximizer(θ) for θ in θ_train];

# ╔═╡ bc883d10-c074-4e55-8848-892e7f512556
md"""
## Regularization

We create a trainable model with the same structure as the true encoder but another set of randomly-initialized weights.
"""

# ╔═╡ 4faaf237-e38f-44a2-a2f8-efe56c0688c6
initial_encoder = Chain(Dense(nb_features, 1), dropfirstdim);

# ╔═╡ 371b6435-b45e-4731-8f65-9aaf82a180bb
md"""
Here is the crucial part where `InferOpt` intervenes: the choice of a clever loss function that enables us to
- differentiate through the shortest path maximizer, even though it is a combinatorial operation
- evaluate the quality of our model based on the paths that it recommends
"""

# ╔═╡ 7d54ce77-2af8-412e-b658-3dbd18d26521
@bind ε Slider(0:0.01:10; default=0.0)

# ╔═╡ 2a57e3b9-2d99-413d-af0a-c5b4a15b84d6
@bind M Slider(2:50; default=5)

# ╔═╡ 039fd9c4-974d-47de-a33a-a5968c3d5548
(ε=ε, M=M)

# ╔═╡ 4107ded4-4e57-4f22-ad50-83735f7a97ff
predictor = PerturbedAdditive(linear_maximizer; ε=ε, nb_samples=M);

# ╔═╡ 915035f5-6284-4e9e-8711-d1771fb718b7
md"""
The regularized predictor is just a thin wrapper around our `linear_maximizer`, but with a very different behavior:
"""

# ╔═╡ 7ea037ee-290a-4a3c-bb2a-bff28bb63523
p_regularized = predictor(θ_train[1]);

# ╔═╡ be133738-eeea-4db2-90d4-47266bf80a65
spy(p_regularized)

# ╔═╡ 4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
md"""
Instead of choosing just one path, it spreads over several possible paths, allowing its output to change smoothly as ``\theta`` varies.
"""

# ╔═╡ 3e384580-500c-4b26-b5ab-d0ec84e1eb40
md"""
## Training

Thanks to this smoothing, we can now train our model with a standard gradient optimizer.
"""

# ╔═╡ d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
regularized_predictor = PerturbedAdditive(linear_maximizer; ε=1.0, nb_samples=5);

# ╔═╡ 4cc3ae85-028c-4952-9ad8-94063cee74ae
begin
	encoder = deepcopy(initial_encoder)
	opt = ADAM();
	loss = FenchelYoungLoss(regularized_predictor);
	# Keep track of metrics
	fylosses = Float64[]
	fyhamming_distances = Float64[]
	data = zip(X_train, Y_train)
end;

# ╔═╡ 5d4aee2c-7bb9-4903-ab4a-b6c9f8362afd
function normalized_hamming_distance(x::AbstractArray{<:Real}, y::AbstractArray{<:Real})
    return mean(x[i] != y[i] for i in eachindex(x))
end;

# ╔═╡ f0220f84-07f7-452f-a975-6f08f27a6d0b
md"""
Training loop:
"""

# ╔═╡ 6ecea2ad-8757-4d5a-acd9-4559728e4603
for epoch in 1:100
    l = 0.
    for (x, y) in zip(X_train, Y_train)
        grads = gradient(Flux.params(encoder)) do
            l += loss(encoder(x), y)
        end
        Flux.update!(opt, Flux.params(encoder), grads)
    end
	Y_train_pred = [linear_maximizer(encoder(x)) for x in X_train];
	train_error = mean(
	    normalized_hamming_distance(y, y_pred)
			for (y, y_pred) in zip(Y_train, Y_train_pred)
	)
	push!(fyhamming_distances, train_error)
    push!(fylosses, l)
end;

# ╔═╡ ba00f149-c675-4dfb-97fb-483df8fa761d
md"""
## Results

Since the Fenchel-Young loss is convex, the training works well:
"""

# ╔═╡ 28eec921-d948-4ace-b0a0-1a35b6f464d7
plot(fylosses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 53521e21-7040-493e-802a-cf75cb4c0f65
@info "Final loss" fylosses[end]

# ╔═╡ 1cf291f1-7a8a-4573-891d-ab84162e0895
plot(fyhamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance")

# ╔═╡ 5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
@info "Final hamming distance" fyhamming_distances[end]

# ╔═╡ e42a5c8f-5511-46e1-9495-8fc198fae087
md"""
## Training when $\theta$ costs are known

Smart "predict then optimize"
"""

# ╔═╡ 7ad675e8-bbe7-41a8-ad53-decdb8267097
begin
	encoder2 = deepcopy(initial_encoder)
	spo_loss = SPOPlusLoss(linear_maximizer);
	spolosses = Float64[]
	spohamming_distances = Float64[]
end;

# ╔═╡ a67d37c9-112e-46ca-8991-a621d3cd594a
for epoch in 1:100
    l = 0.
    for (x, θ, y) in zip(X_train, θ_train, Y_train)
        grads = gradient(Flux.params(encoder2)) do
            l += spo_loss(encoder2(x), θ, y)
        end
        Flux.update!(opt, Flux.params(encoder2), grads)
    end
    push!(spolosses, l)
	Y_train_pred = [linear_maximizer(encoder2(x)) for x in X_train];
	train_error = mean(
	    normalized_hamming_distance(y, y_pred)
			for (y, y_pred) in zip(Y_train, Y_train_pred)
	)
	push!(spohamming_distances, train_error)
end;

# ╔═╡ 8010bd8a-5f63-4ee8-8f23-34b59c0297e4
md"""
## Training when $\theta$ costs are known
"""

# ╔═╡ 1b17fd8f-008e-4064-a866-332071647796
plot(spolosses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 910f89b9-64dd-480b-b6d7-19f8eb61923d
@info "Final loss" spolosses[end]

# ╔═╡ 5a6759db-ad6c-48ac-aff3-266b76c9b715
plot(spohamming_distances, xlabel="Epoch", ylabel="Normalized hamming distance")

# ╔═╡ 953523a6-fa73-46ca-a59d-11bd818f8a11
@info "Final hamming distance" error=spohamming_distances[end] 

# ╔═╡ ee6a4ba8-1342-448a-999d-aa063e883654
md"""
## Training when optimal paths are unknown
"""

# ╔═╡ da2931b6-4c0b-43cf-882f-328f67f963b2
function cost(y; instance)
	θ = true_encoder(instance)
    return return sum(-θ[i] * y[i] for i in eachindex(y))
end;

# ╔═╡ 5eeef94f-5bd3-4165-878b-1b4a66ab71a8
begin
	encoder3 = deepcopy(initial_encoder)
	exp_loss = PerturbedComposition(regularized_predictor, cost);
	exp_losses = Float64[]
	cost_gaps = Float64[]
	optimal_costs = [cost(y; instance=x) for (x, y) in zip(X_train, Y_train)]
	exp_hamming_distances = Float64[]

	# Training loop
	for epoch in 1:3000
	    l = 0.
	    for x in X_train
	        grads = gradient(Flux.params(encoder3)) do
	            l += exp_loss(encoder3(x); instance=x)
	        end
	        Flux.update!(opt, Flux.params(encoder3), grads)
	    end
	    push!(exp_losses, l)
		Y_train_pred = [linear_maximizer(encoder3(x)) for x in X_train];
		
		train_cost_gap = mean(
		    (cost(y_pred; instance=x) - c) / abs(c)
				for (x, c, y_pred) in zip(X_train, optimal_costs, Y_train_pred)
		)
		push!(cost_gaps, train_cost_gap)

		train_error = mean(
		    normalized_hamming_distance(y, y_pred)
				for (y, y_pred) in zip(Y_train, Y_train_pred)
		)
		push!(exp_hamming_distances, train_error)
	end
end;

# ╔═╡ 832fa40e-e4ef-42fb-bc25-133d19a5c579
md"""
## Results
"""

# ╔═╡ 2016349b-cfd5-40ef-bfdd-835db6e0f6fe
plot(exp_losses, xlabel="Epoch", ylabel="Loss")

# ╔═╡ 2eb47163-e8dd-4307-8dff-454cabf81d90
@info "Final loss" exp_losses[end]

# ╔═╡ 18657b2f-108e-4f11-ae34-3d889e10e76d
#plot(cost_gaps, xlabel="Epoch", ylabel="Cost diff")

# ╔═╡ b042bd90-8b5e-4556-b8a9-542e35cdb6de
@info "Final cost gap" error=cost_gaps[end] 

# ╔═╡ b0517fb3-dd81-426f-b6d8-14139fb3e662
plot(exp_hamming_distances, xlabel="Epoch", ylabel="Hamming distances")

# ╔═╡ e302b65c-6c12-4e82-86e6-08af2f7a3e47
@info "Final hamming distance" error=exp_hamming_distances[end] 

# ╔═╡ 5f5733a5-2bb4-4045-8671-f3dc7b0586fb
md"""
# Conclusion


### Perspectives ?
"""

# ╔═╡ d37939ad-4937-46f9-a5f7-5394a8c38ded
md"""
## For more information

- **Main package:** [https://github.com/axelparmentier/InferOpt.jl](https://github.com/axelparmentier/InferOpt.jl)
- paper ?

More advanced examples:
- **Single machine scheduling:** [https://github.com/axelparmentier/SingleMachineScheduling.jl](https://github.com/axelparmentier/SingleMachineScheduling.jl)
- **Two stage spanning tree:** [https://github.com/axelparmentier/TwoStageSpanningTree.jl](https://github.com/axelparmentier/TwoStageSpanningTree.jl)
- **Shortest paths on Warcraft maps:** [https://github.com/LouisBouvier/WarcraftShortestPaths.jl](https://github.com/LouisBouvier/WarcraftShortestPaths.jl)
- **Stochastic vehicle scheduling:** [https://github.com/BatyLeo/StochasticVehicleScheduling.jl](https://github.com/BatyLeo/StochasticVehicleScheduling.jl)
"""

# ╔═╡ fd548869-2e5f-47db-9e29-999b1d323b85
md"""
## Perspectives

> Complete this
"""

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
Distributions = "31c24e10-a181-5473-b8eb-7969acd0382f"
Flux = "587475ba-b771-5e3f-ad9e-33799f191a9c"
GLPK = "60bf3e95-4087-53dc-ae20-288a0d20c6a6"
Graphs = "86223c79-3864-5bf0-83f7-82e725a168b6"
GridGraphs = "dd2b58c7-5af7-4f17-9e46-57c68ac813fb"
Images = "916415d5-f1e6-5110-898d-aaa5f9f070e0"
InferOpt = "4846b161-c94e-4150-8dac-c7ae193c601f"
JuMP = "4076af6c-e467-56ae-b986-b466b2749572"
LinearAlgebra = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"
Plots = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
PlutoUI = "7f904dfe-b85e-4ff6-b463-dae2292396a8"
ProgressMeter = "92933f4c-e287-5a05-a399-4b506db050ca"
Random = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
TikzPictures = "37f6aa50-8035-52d0-81c2-5a1d08754b2d"

[compat]
Distributions = "~0.25.62"
Flux = "~0.13.3"
GLPK = "~1.0.1"
Graphs = "~1.7.1"
GridGraphs = "~0.6.0"
Images = "~0.25.2"
InferOpt = "~0.2.0"
JuMP = "~1.1.1"
Plots = "~1.31.1"
PlutoUI = "~0.7.39"
ProgressMeter = "~1.7.2"
TikzPictures = "~3.4.2"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.3"
manifest_format = "2.0"

[[deps.AbstractFFTs]]
deps = ["ChainRulesCore", "LinearAlgebra"]
git-tree-sha1 = "6f1d9bc1c08f9f4a8fa92e3ea3cb50153a1b40d4"
uuid = "621f4979-c628-5d54-868e-fcf4e3e8185c"
version = "1.1.0"

[[deps.AbstractPlutoDingetjes]]
deps = ["Pkg"]
git-tree-sha1 = "8eaf9f1b4921132a4cff3f36a1d9ba923b14a481"
uuid = "6e696c72-6542-2067-7265-42206c756150"
version = "1.1.4"

[[deps.Adapt]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "af92965fb30777147966f58acb05da51c5616b5f"
uuid = "79e6a3ab-5dfb-504d-930d-738a2a938a0e"
version = "3.3.3"

[[deps.ArgTools]]
uuid = "0dad84c5-d112-42e6-8d28-ef12dabb789f"

[[deps.ArnoldiMethod]]
deps = ["LinearAlgebra", "Random", "StaticArrays"]
git-tree-sha1 = "62e51b39331de8911e4a7ff6f5aaf38a5f4cc0ae"
uuid = "ec485272-7323-5ecc-a04f-4719b315124d"
version = "0.2.0"

[[deps.ArrayInterface]]
deps = ["ArrayInterfaceCore", "Compat", "IfElse", "LinearAlgebra", "Static"]
git-tree-sha1 = "1d062b8ab719670c16024105ace35e6d32988d4f"
uuid = "4fba245c-0d91-5ea0-9b3e-6abc04ee57a9"
version = "6.0.18"

[[deps.ArrayInterfaceCore]]
deps = ["LinearAlgebra", "SparseArrays", "SuiteSparse"]
git-tree-sha1 = "5e732808bcf7bbf730e810a9eaafc52705b38bb5"
uuid = "30b0a656-2188-435a-8636-2ec0e6a096e2"
version = "0.1.13"

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
git-tree-sha1 = "e4e5ece72fa2f108fb20c3c5538a5fa9ef3d668a"
uuid = "052768ef-5323-5732-b1bb-66c8b64840ba"
version = "3.11.0"

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
deps = ["ChainRulesCore", "Compat", "IrrationalConstants", "LinearAlgebra", "Random", "RealDot", "SparseArrays", "Statistics"]
git-tree-sha1 = "238f4cb4d7d58ad876d51bae45922b3fb7db29ad"
uuid = "082447d4-558c-5d27-93f4-14fc19e9eca2"
version = "1.36.1"

[[deps.ChainRulesCore]]
deps = ["Compat", "LinearAlgebra", "SparseArrays"]
git-tree-sha1 = "9489214b993cd42d17f44c36e359bf6a7c919abf"
uuid = "d360d2e6-b24c-11e9-a2a3-2a2ae2dbcce4"
version = "1.15.0"

[[deps.ChangesOfVariables]]
deps = ["ChainRulesCore", "LinearAlgebra", "Test"]
git-tree-sha1 = "1e315e3f4b0b7ce40feded39c73049692126cf53"
uuid = "9e997f8a-9a97-42d5-a9f1-ce6bfc15e2c0"
version = "0.1.3"

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
git-tree-sha1 = "924cdca592bc16f14d2f7006754a621735280b74"
uuid = "34da2185-b29b-5c13-b0c7-acf172513d20"
version = "4.1.0"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.ComputationalResources]]
git-tree-sha1 = "52cb3ec90e8a8bea0e62e275ba577ad0f74821f7"
uuid = "ed09eef8-17a6-5b46-8889-db040fac31e3"
version = "0.3.2"

[[deps.Contour]]
deps = ["StaticArrays"]
git-tree-sha1 = "9f02045d934dc030edad45944ea80dbd1f0ebea7"
uuid = "d38c429a-6771-53c6-b99e-75d170b6e991"
version = "0.5.7"

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
git-tree-sha1 = "28d605d9a0ac17118fe2c5e9ce0fbb76c3ceb120"
uuid = "b552c78f-8df3-52c6-915a-8e097449b14b"
version = "1.11.0"

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
git-tree-sha1 = "0ec161f87bf4ab164ff96dfacf4be8ffff2375fd"
uuid = "31c24e10-a181-5473-b8eb-7969acd0382f"
version = "0.25.62"

[[deps.DocStringExtensions]]
deps = ["LibGit2"]
git-tree-sha1 = "b19534d1895d702889b219c382a6e18010797f0b"
uuid = "ffbed154-4ef7-542d-bbb7-c09d3a79fcae"
version = "0.8.6"

[[deps.Downloads]]
deps = ["ArgTools", "FileWatching", "LibCURL", "NetworkOptions"]
uuid = "f43a241f-c20a-4ad4-852c-f6b1247861c6"

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

[[deps.FFMPEG]]
deps = ["FFMPEG_jll"]
git-tree-sha1 = "b57e3acbe22f8484b4b5ff66a7499717fe1a9cc8"
uuid = "c87230d0-a227-11e9-1b43-d7ebe4e7570a"
version = "0.4.1"

[[deps.FFMPEG_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "JLLWrappers", "LAME_jll", "Libdl", "Ogg_jll", "OpenSSL_jll", "Opus_jll", "Pkg", "Zlib_jll", "libass_jll", "libfdk_aac_jll", "libvorbis_jll", "x264_jll", "x265_jll"]
git-tree-sha1 = "d8a578692e3077ac998b50c0217dfd67f21d1e5f"
uuid = "b22a6f82-2f65-5046-a5b2-351ab43fb4e5"
version = "4.4.0+0"

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

[[deps.FileIO]]
deps = ["Pkg", "Requires", "UUIDs"]
git-tree-sha1 = "9267e5f50b0e12fdfd5a2455534345c4cf2c7f7a"
uuid = "5789e2e9-d7fb-5bc7-8068-2c6fae9b9549"
version = "1.14.0"

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
git-tree-sha1 = "62350a872545e1369b1d8f11358a21681aa73929"
uuid = "587475ba-b771-5e3f-ad9e-33799f191a9c"
version = "0.13.3"

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
git-tree-sha1 = "2f18915445b248731ec5db4e4a17e451020bf21e"
uuid = "f6369f11-7733-5829-9624-2563aa707210"
version = "0.10.30"

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
git-tree-sha1 = "223fffa49ca0ff9ce4f875be001ffe173b2b7de4"
uuid = "d9f16b24-f501-4c13-a1f2-28368ffc5196"
version = "0.2.8"

[[deps.GLFW_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Libglvnd_jll", "Pkg", "Xorg_libXcursor_jll", "Xorg_libXi_jll", "Xorg_libXinerama_jll", "Xorg_libXrandr_jll"]
git-tree-sha1 = "51d2dfe8e590fbd74e7a842cf6d13d8a2f45dc01"
uuid = "0656b61e-2033-5cc2-a64a-77c0f6c09b89"
version = "3.3.6+0"

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

[[deps.GPUArrays]]
deps = ["Adapt", "GPUArraysCore", "LLVM", "LinearAlgebra", "Printf", "Random", "Reexport", "Serialization", "Statistics"]
git-tree-sha1 = "73a4c9447419ce058df716925893e452ba5528ad"
uuid = "0c68f7d7-f131-5f86-a1c3-88cf8149b2d7"
version = "8.4.0"

[[deps.GPUArraysCore]]
deps = ["Adapt"]
git-tree-sha1 = "4078d3557ab15dd9fe6a0cf6f65e3d4937e98427"
uuid = "46192b85-c4d5-4398-a991-12ede77f4527"
version = "0.1.0"

[[deps.GPUCompiler]]
deps = ["ExprTools", "InteractiveUtils", "LLVM", "Libdl", "Logging", "TimerOutputs", "UUIDs"]
git-tree-sha1 = "47f63159f7cb5d0e5e0cfd2f20454adea429bec9"
uuid = "61eb1bfa-7361-4325-ad38-22787b887f55"
version = "0.16.1"

[[deps.GR]]
deps = ["Base64", "DelimitedFiles", "GR_jll", "HTTP", "JSON", "Libdl", "LinearAlgebra", "Pkg", "Printf", "Random", "RelocatableFolders", "Serialization", "Sockets", "Test", "UUIDs"]
git-tree-sha1 = "c98aea696662d09e215ef7cda5296024a9646c75"
uuid = "28b8d3ca-fb5f-59d9-8090-bfdbd6d07a71"
version = "0.64.4"

[[deps.GR_jll]]
deps = ["Artifacts", "Bzip2_jll", "Cairo_jll", "FFMPEG_jll", "Fontconfig_jll", "GLFW_jll", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pixman_jll", "Pkg", "Qt5Base_jll", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "3a233eeeb2ca45842fe100e0413936834215abf5"
uuid = "d2c73de3-f751-5644-a686-071e5b155ba9"
version = "0.64.4+0"

[[deps.GeometryBasics]]
deps = ["EarCut_jll", "IterTools", "LinearAlgebra", "StaticArrays", "StructArrays", "Tables"]
git-tree-sha1 = "83ea630384a13fc4f002b77690bc0afeb4255ac9"
uuid = "5c1252a2-5f33-56bf-86c9-59e7332b4326"
version = "0.4.2"

[[deps.Gettext_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Libiconv_jll", "Pkg", "XML2_jll"]
git-tree-sha1 = "9b02998aba7bf074d14de89f9d37ca24a1a0b046"
uuid = "78b55507-aeef-58d4-861c-77aaff3498b1"
version = "0.21.0+0"

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
git-tree-sha1 = "db5c7e27c0d46fd824d470a3c32a4fc6c935fa96"
uuid = "86223c79-3864-5bf0-83f7-82e725a168b6"
version = "1.7.1"

[[deps.GridGraphs]]
deps = ["DataStructures", "Graphs", "SparseArrays"]
git-tree-sha1 = "a8fe4ca4d518e40cea55e551c3ac8124d7339938"
uuid = "dd2b58c7-5af7-4f17-9e46-57c68ac813fb"
version = "0.6.0"

[[deps.Grisu]]
git-tree-sha1 = "53bb909d1151e57e2484c3d1b53e19552b887fb2"
uuid = "42e2da0e-8278-4e71-bc24-59509adca0fe"
version = "1.0.2"

[[deps.HTTP]]
deps = ["Base64", "Dates", "IniFile", "Logging", "MbedTLS", "NetworkOptions", "Sockets", "URIs"]
git-tree-sha1 = "0fa77022fe4b511826b39c894c90daf5fce3334a"
uuid = "cd3eb016-35fb-5094-929b-558a96fad6f3"
version = "0.9.17"

[[deps.HarfBuzz_jll]]
deps = ["Artifacts", "Cairo_jll", "Fontconfig_jll", "FreeType2_jll", "Glib_jll", "Graphite2_jll", "JLLWrappers", "Libdl", "Libffi_jll", "Pkg"]
git-tree-sha1 = "129acf094d168394e80ee1dc4bc06ec835e510a3"
uuid = "2e76f6c2-a576-52d4-95c1-20adfe4de566"
version = "2.8.1+1"

[[deps.HypergeometricFunctions]]
deps = ["DualNumbers", "LinearAlgebra", "SpecialFunctions", "Test"]
git-tree-sha1 = "cb7099a0109939f16a4d3b572ba8396b1f6c7c31"
uuid = "34004b35-14d8-5ef3-9330-4cdb6864b03a"
version = "0.3.10"

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
git-tree-sha1 = "7a20463713d239a19cbad3f6991e404aca876bda"
uuid = "51556ac3-7006-55f5-8cb3-34580c88182d"
version = "0.2.15"

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
deps = ["FileIO", "ImageCore", "ImageMagick_jll", "InteractiveUtils"]
git-tree-sha1 = "ca8d917903e7a1126b6583a097c5cb7a0bedeac1"
uuid = "6218d12a-5da1-5696-b52f-db25d2ecc6d1"
version = "1.2.2"

[[deps.ImageMagick_jll]]
deps = ["JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg", "Zlib_jll", "libpng_jll"]
git-tree-sha1 = "1c0a2295cca535fabaf2029062912591e9b61987"
uuid = "c73af94c-d91f-53ed-93a7-00f77d67a9d7"
version = "6.9.10-12+3"

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
deps = ["ImageContrastAdjustment", "ImageCore", "ImageDistances", "ImageFiltering", "OffsetArrays", "Statistics"]
git-tree-sha1 = "1d2d73b14198d10f7f12bf7f8481fd4b3ff5cd61"
uuid = "2996bd0c-7a13-11e9-2da2-2f5ce47296a9"
version = "0.3.0"

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
git-tree-sha1 = "42fe8de1fe1f80dab37a39d391b6301f7aeaa7b8"
uuid = "02fcd773-0e25-5acc-982a-7f6622650795"
version = "0.9.4"

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
deps = ["ChainRulesCore", "LinearAlgebra", "Random", "SimpleTraits", "SparseArrays", "Statistics", "Test"]
git-tree-sha1 = "1a4d7a524100834994dd0e12705856133975dd68"
uuid = "4846b161-c94e-4150-8dac-c7ae193c601f"
version = "0.2.0"

[[deps.Inflate]]
git-tree-sha1 = "f5fc07d4e706b84f72d54eedcc1c13d92fb0871c"
uuid = "d25df0c9-e2be-5dd7-82c8-3ad0b3e990b9"
version = "0.1.2"

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
deps = ["AxisAlgorithms", "ChainRulesCore", "LinearAlgebra", "OffsetArrays", "Random", "Ratios", "Requires", "SharedArrays", "SparseArrays", "StaticArrays", "WoodburyMatrices"]
git-tree-sha1 = "b7bc05649af456efc75d178846f47006c2c4c3c7"
uuid = "a98d9a8b-a2ab-59e6-89dd-64a1c18fca59"
version = "0.13.6"

[[deps.IntervalSets]]
deps = ["Dates", "Random", "Statistics"]
git-tree-sha1 = "57af5939800bce15980bddd2426912c4f83012d8"
uuid = "8197267c-284f-5f27-9208-e0e47529a953"
version = "0.7.1"

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
deps = ["Calculus", "DataStructures", "ForwardDiff", "LinearAlgebra", "MathOptInterface", "MutableArithmetics", "NaNMath", "OrderedCollections", "Printf", "SparseArrays", "SpecialFunctions"]
git-tree-sha1 = "534adddf607222b34a0a9bba812248a487ab22b7"
uuid = "4076af6c-e467-56ae-b986-b466b2749572"
version = "1.1.1"

[[deps.LAME_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "f6250b16881adf048549549fba48b1161acdac8c"
uuid = "c1c5ebd0-6772-5130-a774-d5fcae4a789d"
version = "3.100.1+0"

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
git-tree-sha1 = "46a39b9c58749eefb5f2dc1178cb8fab5332b1ab"
uuid = "23fbe1c1-3f47-55db-b15f-69d7ec21a316"
version = "0.15.15"

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

[[deps.LibCURL_jll]]
deps = ["Artifacts", "LibSSH2_jll", "Libdl", "MbedTLS_jll", "Zlib_jll", "nghttp2_jll"]
uuid = "deac9b47-8bc7-5906-a0fe-35ac56dc84c0"

[[deps.LibGit2]]
deps = ["Base64", "NetworkOptions", "Printf", "SHA"]
uuid = "76f85450-5226-5b5a-8eaa-529ad045b433"

[[deps.LibSSH2_jll]]
deps = ["Artifacts", "Libdl", "MbedTLS_jll"]
uuid = "29816b5a-b9ab-546f-933c-edad1886dfa8"

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

[[deps.LittleCMS_jll]]
deps = ["Artifacts", "JLLWrappers", "JpegTurbo_jll", "Libdl", "Libtiff_jll", "Pkg"]
git-tree-sha1 = "110897e7db2d6836be22c18bffd9422218ee6284"
uuid = "d3a379c0-f9a3-5b72-a4c0-6bf4d2e8af0f"
version = "2.12.0+0"

[[deps.LogExpFunctions]]
deps = ["ChainRulesCore", "ChangesOfVariables", "DocStringExtensions", "InverseFunctions", "IrrationalConstants", "LinearAlgebra"]
git-tree-sha1 = "09e4b894ce6a976c354a69041a04748180d43637"
uuid = "2ab3a3ac-af41-5b50-aa03-7779005ae688"
version = "0.3.15"

[[deps.Logging]]
uuid = "56ddb016-857b-54e1-b83d-db4d58db5568"

[[deps.MKL_jll]]
deps = ["Artifacts", "IntelOpenMP_jll", "JLLWrappers", "LazyArtifacts", "Libdl", "Pkg"]
git-tree-sha1 = "e595b205efd49508358f7dc670a940c790204629"
uuid = "856f044c-d86e-5d09-b602-aeab76dc8ba7"
version = "2022.0.0+0"

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
git-tree-sha1 = "c167b0d6d165ce49f35fbe2ee1aea8844e7c7cea"
uuid = "b8f27783-ece8-5eb3-8dc8-9495eed66fee"
version = "1.4.0"

[[deps.MbedTLS]]
deps = ["Dates", "MbedTLS_jll", "Random", "Sockets"]
git-tree-sha1 = "1c38e51c3d08ef2278062ebceade0e46cefc96fe"
uuid = "739be429-bea8-5141-9913-cc70e7f3736d"
version = "1.0.3"

[[deps.MbedTLS_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "c8ffd9c3-330d-5841-b78e-0817d7145fa1"

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

[[deps.MutableArithmetics]]
deps = ["LinearAlgebra", "SparseArrays", "Test"]
git-tree-sha1 = "4e675d6e9ec02061800d6cfb695812becbd03cdf"
uuid = "d8a4904e-b15c-11e9-3269-09a3773c0cb0"
version = "1.0.4"

[[deps.NNlib]]
deps = ["Adapt", "ChainRulesCore", "LinearAlgebra", "Pkg", "Requires", "Statistics"]
git-tree-sha1 = "1a80840bcdb73de345230328d49767ab115be6f2"
uuid = "872c559c-99b0-510c-b3b7-b6c96a88d5cd"
version = "0.8.8"

[[deps.NNlibCUDA]]
deps = ["CUDA", "LinearAlgebra", "NNlib", "Random", "Statistics"]
git-tree-sha1 = "e161b835c6aa9e2339c1e72c3d4e39891eac7a4f"
uuid = "a00861dc-f156-4864-bf3c-e6376f28a68d"
version = "0.2.3"

[[deps.NaNMath]]
git-tree-sha1 = "737a5957f387b17e74d4ad2f440eb330b39a62c5"
uuid = "77ba4419-2d1f-58cd-9bb1-8ffee604a2e3"
version = "1.0.0"

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

[[deps.OffsetArrays]]
deps = ["Adapt"]
git-tree-sha1 = "ec2e30596282d722f018ae784b7f44f3b88065e4"
uuid = "6fe1bfb0-de20-5000-8ca7-80f57d26f881"
version = "1.12.6"

[[deps.Ogg_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "887579a3eb005446d514ab7aeac5d1d027658b8f"
uuid = "e7412a2a-1a6e-54c0-be00-318e2571c051"
version = "1.3.5+1"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

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

[[deps.OpenSSL_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "9a36165cf84cff35851809a40a928e1103702013"
uuid = "458c3c95-2e84-50aa-8efc-19380b2a3a95"
version = "1.1.16+0"

[[deps.OpenSpecFun_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "13652491f6856acfd2db29360e1bbcd4565d04f1"
uuid = "efe28fd5-8261-553b-a9e1-b2916fc3738e"
version = "0.5.5+0"

[[deps.Optimisers]]
deps = ["ChainRulesCore", "Functors", "LinearAlgebra", "Random", "Statistics"]
git-tree-sha1 = "afb2b39a354025a6db6decd68f2ef5353e8ff1ae"
uuid = "3bd65402-5787-11e9-1adc-39752487f4e2"
version = "0.2.7"

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
git-tree-sha1 = "ca433b9e2f5ca3a0ce6702a032fce95a3b6e1e48"
uuid = "90014a1f-27ba-587c-ab20-58faa44d9150"
version = "0.11.14"

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

[[deps.PkgVersion]]
deps = ["Pkg"]
git-tree-sha1 = "a7a7e1a88853564e551e4eba8650f8c38df79b37"
uuid = "eebad327-c553-4316-9ea0-9fa01ccd7688"
version = "0.1.1"

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
deps = ["Base64", "Contour", "Dates", "Downloads", "FFMPEG", "FixedPointNumbers", "GR", "GeometryBasics", "JSON", "Latexify", "LinearAlgebra", "Measures", "NaNMath", "Pkg", "PlotThemes", "PlotUtils", "Printf", "REPL", "Random", "RecipesBase", "RecipesPipeline", "Reexport", "Requires", "Scratch", "Showoff", "SparseArrays", "Statistics", "StatsBase", "UUIDs", "UnicodeFun", "Unzip"]
git-tree-sha1 = "93e82cebd5b25eb33068570e3f63a86be16955be"
uuid = "91a5bcdd-55d7-5caf-9e0b-520d859cae80"
version = "1.31.1"

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
git-tree-sha1 = "afeacaecf4ed1649555a19cb2cad3c141bbc9474"
uuid = "74087812-796a-5b5d-8853-05524746bad3"
version = "1.5.0"

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
git-tree-sha1 = "dc1e451e15d90347a7decc4221842a022b011714"
uuid = "01d81517-befc-4cb6-b9ec-a95719d0359c"
version = "0.5.2"

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
git-tree-sha1 = "cdbd3b1338c72ce29d9584fdbe9e9b70eeb5adca"
uuid = "05181044-ff0b-4ac5-8273-598c1e38db00"
version = "0.1.3"

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

[[deps.Scratch]]
deps = ["Dates"]
git-tree-sha1 = "0b4b7f1393cff97c33891da2a0bf69c6ed241fda"
uuid = "6c6a2e73-6563-6170-7368-637461726353"
version = "1.1.0"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

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
git-tree-sha1 = "a9e798cae4867e3a41cae2dd9eb60c047f1212db"
uuid = "276daf66-3868-5448-9aa4-cd146d93841b"
version = "2.1.6"

[[deps.StackViews]]
deps = ["OffsetArrays"]
git-tree-sha1 = "46e589465204cd0c08b4bd97385e4fa79a0c770c"
uuid = "cae243ae-269e-4f55-b966-ac2d0dc13c15"
version = "0.1.1"

[[deps.Static]]
deps = ["IfElse"]
git-tree-sha1 = "11f1b69a28b6e4ca1cc18342bfab7adb7ff3a090"
uuid = "aedffcd0-7271-4cad-89d0-dc628f76c6d3"
version = "0.7.3"

[[deps.StaticArrays]]
deps = ["LinearAlgebra", "Random", "StaticArraysCore", "Statistics"]
git-tree-sha1 = "9f8a5dc5944dc7fbbe6eb4180660935653b0a9d9"
uuid = "90137ffa-7385-5640-81b9-e52037218182"
version = "1.5.0"

[[deps.StaticArraysCore]]
git-tree-sha1 = "6edcea211d224fa551ec8a85debdc6d732f155dc"
uuid = "1e83bf80-4336-4d27-bf5d-d5a4f845583c"
version = "1.0.0"

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.StatsAPI]]
deps = ["LinearAlgebra"]
git-tree-sha1 = "2c11d7290036fe7aac9038ff312d3b3a2a5bf89e"
uuid = "82ae8749-77ed-4fe6-ae5f-f523153014b0"
version = "1.4.0"

[[deps.StatsBase]]
deps = ["DataAPI", "DataStructures", "LinearAlgebra", "LogExpFunctions", "Missings", "Printf", "Random", "SortingAlgorithms", "SparseArrays", "Statistics", "StatsAPI"]
git-tree-sha1 = "642f08bf9ff9e39ccc7b710b2eb9a24971b52b1a"
uuid = "2913bbd2-ae8a-5f71-8c99-4fb6c76f3a91"
version = "0.33.17"

[[deps.StatsFuns]]
deps = ["ChainRulesCore", "HypergeometricFunctions", "InverseFunctions", "IrrationalConstants", "LogExpFunctions", "Reexport", "Rmath", "SpecialFunctions"]
git-tree-sha1 = "5783b877201a82fc0014cbf381e7e6eb130473a4"
uuid = "4c63d2b9-4356-54db-8cca-17b64c39e42c"
version = "1.0.1"

[[deps.StructArrays]]
deps = ["Adapt", "DataAPI", "StaticArrays", "Tables"]
git-tree-sha1 = "ec47fb6069c57f1cee2f67541bf8f23415146de7"
uuid = "09ab397b-f2b6-538f-b94a-2f83cf4a842a"
version = "0.6.11"

[[deps.SuiteSparse]]
deps = ["Libdl", "LinearAlgebra", "Serialization", "SparseArrays"]
uuid = "4607b0f0-06f3-5cda-b6b1-a6196a1729e9"

[[deps.TOML]]
deps = ["Dates"]
uuid = "fa267f1f-6049-4f14-aa54-33bafae1ed76"

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
git-tree-sha1 = "fcf41697256f2b759de9380a7e8196d6516f0310"
uuid = "731e570b-9d59-4bfa-96dc-6df516fadf69"
version = "0.6.0"

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
git-tree-sha1 = "464d64b2510a25e6efe410e7edab14fffdc333df"
uuid = "a759f4b9-e2f1-59dc-863e-4aeb61b1ea8f"
version = "0.5.20"

[[deps.TranscodingStreams]]
deps = ["Random", "Test"]
git-tree-sha1 = "216b95ea110b5972db65aa90f88d8d89dcb8851c"
uuid = "3bb67fe8-82b1-5028-8e26-92a6c54297fa"
version = "0.9.6"

[[deps.Tricks]]
git-tree-sha1 = "6bac775f2d42a611cdfcd1fb217ee719630c4175"
uuid = "410a4b4d-49e4-4fbc-ab6d-cb71b17b3775"
version = "0.1.6"

[[deps.URIs]]
git-tree-sha1 = "97bbe755a53fe859669cd907f2d96aee8d2c1355"
uuid = "5c2747f8-b7ea-4ff2-ba2e-563bfd36b1d4"
version = "1.3.0"

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

[[deps.Zstd_jll]]
deps = ["Artifacts", "JLLWrappers", "Libdl", "Pkg"]
git-tree-sha1 = "e45044cd873ded54b6a5bac0eb5c971392cf1927"
uuid = "3161d3a3-bdf6-5164-811a-617609db77b4"
version = "1.5.2+0"

[[deps.Zygote]]
deps = ["AbstractFFTs", "ChainRules", "ChainRulesCore", "DiffRules", "Distributed", "FillArrays", "ForwardDiff", "IRTools", "InteractiveUtils", "LinearAlgebra", "MacroTools", "NaNMath", "Random", "Requires", "SparseArrays", "SpecialFunctions", "Statistics", "ZygoteRules"]
git-tree-sha1 = "a49267a2e5f113c7afe93843deea7461c0f6b206"
uuid = "e88e6eb3-aa80-5325-afca-941959d7151f"
version = "0.6.40"

[[deps.ZygoteRules]]
deps = ["MacroTools"]
git-tree-sha1 = "8c1a8e4dfacb1fd631745552c8db35d0deb09ea0"
uuid = "700de1a5-db45-46bc-99cf-38207098b444"
version = "0.2.2"

[[deps.libass_jll]]
deps = ["Artifacts", "Bzip2_jll", "FreeType2_jll", "FriBidi_jll", "HarfBuzz_jll", "JLLWrappers", "Libdl", "Pkg", "Zlib_jll"]
git-tree-sha1 = "5982a94fcba20f02f42ace44b9894ee2b140fe47"
uuid = "0ac62f75-1d6f-5e53-bd7c-93b484bb37c0"
version = "0.15.1+0"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"

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

[[deps.p7zip_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "3f19e933-33d8-53b3-aaab-bd5110c3b7a0"

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
git-tree-sha1 = "ece2350174195bb31de1a63bea3a41ae1aa593b6"
uuid = "d8fb68d0-12a3-5cfd-a85a-d49703b185fd"
version = "0.9.1+5"
"""

# ╔═╡ Cell order:
# ╠═9de3b7ab-14b0-4a79-bd51-6202f7cdfdfd
# ╠═0617b570-c163-4bd6-8a6b-e49653c1af7f
# ╟─e716f94c-1f4a-4616-bc65-c1e48723bfe3
# ╟─a8a40434-4b36-411c-b364-a1056b8295a5
# ╠═d6c80374-a253-4943-98fb-977c6deefa1d
# ╠═62ccfefa-9c5e-4b8f-94e0-8d17b54438da
# ╟─eab0af69-82ba-43f1-bc40-7fddfe7b2e12
# ╟─3ff8833b-e8d8-4621-b062-d3065de91ba6
# ╟─c820e809-5d03-4073-8326-1fe782decb44
# ╟─5b6d013f-2d8c-4919-8fe4-4af5219c3634
# ╟─5cb8738a-7c85-4c88-984e-5a86fcd7acd5
# ╟─afc55865-b3f2-4f39-8c00-2c38957f0289
# ╟─04e00283-05c2-4b1b-8c44-54fb1dddb124
# ╟─ec6237ae-e7d8-4191-bc2c-8722b7b9fe63
# ╟─e1badec7-4b93-4308-9356-16577e398fe9
# ╟─fcb144ba-5477-49da-a32c-232545f7511b
# ╟─c6bf44df-f4a3-4fda-8aa8-d565849acdde
# ╟─ad1a47b9-d9d3-4f39-ad8e-7749c651da12
# ╟─f0ee67da-ff8b-4229-a1fc-3be190a2d0b1
# ╟─4c661db2-312a-4e03-8f66-df2bb68ad9a7
# ╟─d32c406d-f3d2-450d-a42d-d1ccab1b66b0
# ╟─1a1e818a-d774-417e-bd5c-18f88e116635
# ╟─52ca4280-f092-4941-aed5-e3fc25b3149a
# ╟─88ba9bb1-02b3-4f32-bf6c-be8f99626f13
# ╟─f2df0373-b253-4abf-9719-462512ab029f
# ╟─ea2faddf-38b2-46ab-9a53-2057ade1f198
# ╟─06c9d007-7fe8-489d-baa9-7264f83cc0d0
# ╟─77423e24-7eca-4352-8ee3-0fa7b6e4b687
# ╟─7a6a9c59-df26-4f81-b0b1-77ee99d98810
# ╟─916ff5c3-dbec-417b-a6eb-d99c7df7fc8b
# ╟─5f023b91-b0ae-4e91-94fb-f56312c8135f
# ╟─c06b600f-3a79-416e-b2d8-3d85c571d2c8
# ╟─155ee558-8b6f-446b-adbe-41355e9745c0
# ╟─73f9d834-82d6-472c-8c66-ea85005c9287
# ╟─0f9a59ac-4a82-4bbd-b662-344491304c53
# ╟─3dfd513a-d8c0-4e04-aa57-02ee1a63367e
# ╟─f62f7d6f-a0f8-4dd4-806c-549f6773b020
# ╟─bf2619d5-8f84-4340-9e6f-8343d687fc03
# ╟─296fc611-5d26-44c4-8df8-209401a8582a
# ╟─7c7a76b5-ff7e-4731-96f4-49100d59e03a
# ╟─36bd5f9b-1354-440a-b6b1-238f0f0def5e
# ╟─b7477763-33b6-4506-a253-f0700472788d
# ╟─cb51241e-e327-4a3e-906b-47a3d51b1771
# ╟─cd4f2546-fe46-42db-8197-7278ccd32cbe
# ╟─fa13eb7d-d6f9-48a8-9745-98bdc7e4ede0
# ╟─1484d096-0beb-44d7-8192-6948f3ccd7ca
# ╟─90c505c4-bd2d-4e95-96fd-1385672d2558
# ╟─60e0f981-8eb6-4d5e-b38a-a973cf40be3a
# ╠═3b1bffd7-de24-405c-ae09-40223bc0b76d
# ╠═d5e45cdf-7955-46fb-ab23-07f57a37fccc
# ╟─455a316f-ddc4-4eb0-b185-ed8dd5ff1589
# ╟─9f293911-323f-4c91-926b-cff0927c16a1
# ╟─86c31ee6-2b45-46c0-99ef-8e8da7c67717
# ╟─53bd8687-a7bb-43b6-b4b1-f487c9fa40af
# ╟─9d28cfad-1ee4-4946-9090-6d06ed985761
# ╠═0f275285-a5be-4c97-862d-71193e9ac444
# ╠═25f0cc4d-f659-44f3-8319-e9a12f8c563a
# ╠═003ba2de-5aee-4c7d-9af6-2472f714e483
# ╠═5ce19f81-2205-4fc2-88dc-ff8e3c50c28e
# ╟─7d2e7333-eded-4168-9364-0b7b63f5acd3
# ╠═ef88fae7-1baf-44bc-8405-20acdb9301a0
# ╠═b42d417d-aa67-4988-8c4a-dd105d0353f8
# ╟─4633febc-b1ce-43a6-8f3a-854e29c56beb
# ╟─3614c791-ce6d-41f2-94ae-ed01cf15fbae
# ╠═28437714-35d6-47dd-8609-441fa0a68eda
# ╠═6aac7a6a-14e3-4f36-ab18-f232a31813f4
# ╠═bc03dc04-bcac-4e4a-aeda-9a6b90f495e1
# ╠═c8c4cfaa-1890-4ee0-8778-fed5cf188892
# ╟─a58364b1-debb-4c5d-9f69-6dadb2a57ffa
# ╠═458ab7d6-45dc-43d4-85ed-8ea355aca06d
# ╟─67081a13-78fd-485a-89c5-0ca04479a76a
# ╠═4435ed2f-718b-444e-8c2b-a7c04cde8ad8
# ╟─9f52266e-3ad3-4823-a1ab-dd08294136d6
# ╠═04ca9af8-d29b-4694-af98-fce02036023f
# ╠═bd4c8210-75ac-45bc-8aa2-4f34dd0fd852
# ╟─bc883d10-c074-4e55-8848-892e7f512556
# ╠═4faaf237-e38f-44a2-a2f8-efe56c0688c6
# ╟─371b6435-b45e-4731-8f65-9aaf82a180bb
# ╠═7d54ce77-2af8-412e-b658-3dbd18d26521
# ╠═2a57e3b9-2d99-413d-af0a-c5b4a15b84d6
# ╠═039fd9c4-974d-47de-a33a-a5968c3d5548
# ╠═4107ded4-4e57-4f22-ad50-83735f7a97ff
# ╟─915035f5-6284-4e9e-8711-d1771fb718b7
# ╠═7ea037ee-290a-4a3c-bb2a-bff28bb63523
# ╠═be133738-eeea-4db2-90d4-47266bf80a65
# ╟─4b66eabd-eae6-4ee1-9555-a2baf43c8a2e
# ╟─3e384580-500c-4b26-b5ab-d0ec84e1eb40
# ╠═d3b46a83-2a9c-49b1-b9be-10e5b8848f9a
# ╠═4cc3ae85-028c-4952-9ad8-94063cee74ae
# ╠═5d4aee2c-7bb9-4903-ab4a-b6c9f8362afd
# ╟─f0220f84-07f7-452f-a975-6f08f27a6d0b
# ╠═6ecea2ad-8757-4d5a-acd9-4559728e4603
# ╟─ba00f149-c675-4dfb-97fb-483df8fa761d
# ╠═28eec921-d948-4ace-b0a0-1a35b6f464d7
# ╠═53521e21-7040-493e-802a-cf75cb4c0f65
# ╠═1cf291f1-7a8a-4573-891d-ab84162e0895
# ╠═5ec3cc3f-3bfb-4bfd-8014-728bf27e140e
# ╟─e42a5c8f-5511-46e1-9495-8fc198fae087
# ╠═7ad675e8-bbe7-41a8-ad53-decdb8267097
# ╠═a67d37c9-112e-46ca-8991-a621d3cd594a
# ╟─8010bd8a-5f63-4ee8-8f23-34b59c0297e4
# ╠═1b17fd8f-008e-4064-a866-332071647796
# ╠═910f89b9-64dd-480b-b6d7-19f8eb61923d
# ╠═5a6759db-ad6c-48ac-aff3-266b76c9b715
# ╠═953523a6-fa73-46ca-a59d-11bd818f8a11
# ╟─ee6a4ba8-1342-448a-999d-aa063e883654
# ╠═da2931b6-4c0b-43cf-882f-328f67f963b2
# ╠═5eeef94f-5bd3-4165-878b-1b4a66ab71a8
# ╟─832fa40e-e4ef-42fb-bc25-133d19a5c579
# ╠═2016349b-cfd5-40ef-bfdd-835db6e0f6fe
# ╠═2eb47163-e8dd-4307-8dff-454cabf81d90
# ╠═18657b2f-108e-4f11-ae34-3d889e10e76d
# ╠═b042bd90-8b5e-4556-b8a9-542e35cdb6de
# ╠═b0517fb3-dd81-426f-b6d8-14139fb3e662
# ╠═e302b65c-6c12-4e82-86e6-08af2f7a3e47
# ╠═5f5733a5-2bb4-4045-8671-f3dc7b0586fb
# ╟─d37939ad-4937-46f9-a5f7-5394a8c38ded
# ╟─fd548869-2e5f-47db-9e29-999b1d323b85
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
