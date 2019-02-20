GROUP_BY = "#groupby";

function render(datasets, chart){
    var ctx = chart.getContext('2d');
    var scatterChart = new Chart(ctx, {
        type: 'scatter',
        data: {
            datasets,
        },
        options: {
            tooltips: {
                callbacks: {
                label: function(tooltipItem, data) {
                    var label = datasets[tooltipItem.datasetIndex].labels[tooltipItem.index];
                    return label + '\n: (' + moment(tooltipItem.xLabel).format('MMMM Do YYYY, h:mm:ss a') + ', ' + tooltipItem.yLabel + ')';
                }
                }
            },
            scales: {
                xAxes: [{
                    type: 'time',
                }]
            }
        }
    });
    chart.onclick = function(evt){
        var item = scatterChart.getElementAtEvent(evt)[0];
        var str = "";
        if(item){
            let data = datasets[item._datasetIndex].raw_data[item._index];
            for(key in data){
                let value = data[key];
                switch(key){
                    case "time":
                        break;
                    case "timestamp":
                        value = Date(value);
                    default:
                    str += key + ": " + value + "\n";
                }
            }
            alert(str);
        }
    };
}



function dataset(name, idx){
    return {label: name, labels: [], data: [], showLine: false,
            raw_data: [],
    };
}

function objectify( row ){
    if(row.length!=11) throw new Error("Row length unexpected "+ row + row.length.toString());

    return { project_name: row[0], 
      build_id: row[1],
      suite_name: row[2],
      test_name: row[3],
      kw_name: row[4],
      robot_tag: row[5],
      python_tag: row[6],
      timestamp: row[7],
      time: Date.parse(row[7]),
      metric: row[8],
      totalTime: row[9],
      totalCalls: row[10] }
}


function shouldShow(row, filters){
    var shouldShow = true;
    for(key in filters){
        if( row[key] === filters[key] || filters[key] === GROUP_BY){
            shouldShow &= true;
        }else{
            shouldShow &= false;
        }
    }
    return shouldShow;
}

function parseCSV(rawdata){
    var lines = rawdata.split("\n");
    rows = []
    for(idx in lines){
        line = lines[idx];
        if(line.trim().length>0){
            parts = line.split(",");
            rows.push(parts);
        }
    }
    return rows;
}

function csv2Datasets(rows, filters){
    var datasets = {};
    var groupBy = "metric";

    for(key in filters){
        if( filters[key].toLowerCase() == "#groupby" ){
            groupBy = key;
        }
    }

    for(idx in rows){
        if(rows[ idx ].length == 0) next;
        let row = objectify( rows[ idx ] );
        let label = [row["suite_name"], row["test_name"]].join(",");

        if(shouldShow(row, filters)){
            let metric = row[groupBy];
            if(metric){
                if (!(metric in datasets)) datasets[metric] = dataset(metric, Object.keys(datasets).length);
                datasets[metric].labels.push(label);
                datasets[metric].raw_data.push(row);
                datasets[metric].data.push({x: row.time, y: row.totalTime});
            }
        }
    }

    var datasetList = Object.values(datasets)
    for(idx in datasetList){
        datasetList[idx].backgroundColor = "#" + palette('tol', datasetList.length)[idx];
    }

    return datasetList;
}

function showChart(rows, chart){
    var filters = JSON.parse(chart.getAttribute("data-filter"));
    var datasets = csv2Datasets(rows, filters);
    render(datasets, chart);
}

function customFilter(section){
    let textfield = section.querySelector('textarea');
    var customFilterText = JSON.parse(textfield.value);
    var datasets = csv2Datasets(window.rows, customFilterText);
    render(datasets, section.querySelector("canvas"));    
}

function reqListener() {
    var rows = parseCSV(this.responseText);
    window.rows = rows;
    let unique_values_for_columns = allValues(rows);
    Array.from(document.getElementsByClassName("perfviewer")).map(
        function(chart){showChart(rows, chart)});
    Array.from(document.getElementsByClassName("customPerfViewer")).map(
            function(section){
                customFilter(section)
                updateSelectors(section, unique_values_for_columns);
            });
    let help = helperString(unique_values_for_columns);
    Array.from(document.getElementsByClassName("helperString")).map(
            function(span){span.innerHTML = help});
        
}

function reqError(err) {
    console.log('Fetch Error :-S', err);
}

function allValues(rows){
    let example_object = objectify(rows[0]);
    delete example_object["time"];
    delete example_object["timestamp"];
    delete example_object["totalTime"];
    delete example_object["totalCalls"];

    let columns = Object.keys(example_object);
    let unique_values_for_columns = {};

    for(idx in columns){
        let column = columns[idx];
        unique_values_for_columns[ column ] = {};
    }

    for(idx in rows){
        let row = objectify(rows[idx]);
        for( colname in example_object){
            unique_values_for_columns[colname][row[colname]] = row[colname];
        }
    }
    
    let rc = {};
    for( colname in unique_values_for_columns){
        let values = Object.keys(unique_values_for_columns[colname]);
        rc[colname] = values;
    }
    return rc;
}

function helperString(unique_values_for_columns){
    let rc = ""
    for( colname in unique_values_for_columns){
        let values = unique_values_for_columns[colname];
        rc += colname + " one of " + values.join(", ") + "<br/>";
    }
    return rc;
}

function option(name, value){
    let option = document.createElement("option");
    if(value) option.setAttribute("value", value);
    option.innerHTML = name;
    return option;
}

function onSelect(evt){
    var sectionAncestor = evt.target.closest("section");
    var textarea = sectionAncestor.querySelector("textarea");
    var colname = evt.target.name;
    var value = evt.target.value;
    var obj = JSON.parse(textarea.value);

    if(value && colname!=value){
        obj[colname] = value;
    }else{
        delete obj[colname];
    }
    textarea.innerHTML = JSON.stringify(obj);
    customFilter(sectionAncestor);
}

function updateSelectors(parent, unique_values_for_columns){
    let defaultValues = JSON.parse(parent.querySelector('textarea').value);

    for( colname in unique_values_for_columns){
        let values = unique_values_for_columns[colname];
        let selectors = parent.querySelectorAll('select[name="'+ colname + '"');
        Array.from(selectors).map(
            function (selector){
                selector.setAttribute("disabled", "disabled")
                values.filter((value)=>value.length>0)
                    .map((value) => {
                        selector.appendChild(option("#"+value, value));
                        selector.removeAttribute("disabled");

                });
                selector.appendChild(option("Group By", "#groupby"));
                selector.appendChild(option("ALL", colname));
                selector.value = defaultValues[colname] || colname;
                selector.addEventListener("change", onSelect);
            });
    }
}
    
var oReq = new XMLHttpRequest();
oReq.onload = reqListener;
oReq.onerror = reqError;
oReq.open('get', './foo.csv', true);
oReq.send();
