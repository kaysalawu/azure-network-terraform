%{~ for node, params in NODES }

## ${node}

| Item    | Value  |
|--------|--------|
%{~ for k, v in params }
%{~ if k == "SUBNETS" }
| *Subnets*|        |
%{~ for x, y in v }
| ${x}   | ${y}   |
%{~ endfor }
| - | -  |
%{~ endif }
%{~ if k != "SUBNETS" && try(v, "") != ""  }
| ${k}   | ${v}   |
%{~ endif }
%{~ endfor }
%{~ endfor }
