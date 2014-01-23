# Something on the interwebs said this is how cool kids use jQuery with CoffeeScript.  I really
# want to be one of the cool kids, so here it is.
$ = jQuery

$ ->
  form = $("#ingest-form-container")
  if form.length != 0
    attachVocabularyListeners()

    # This is how we ensure whatever state the form starts on, typeaheads are properly set up
    form.find("select.type-selector").change()

# Sets up listeners on the type dropdowns to check for attaching or removing typeaheads
attachVocabularyListeners = () ->
  $(document).on "change", "#ingest-form-container select.type-selector", (event) ->
    input = $(this).closest(".form-fields-wrapper").find("input.value-field")
    checkControlledVocabulary(input, $(this))

# Iterates over group divs and sets "data-typeahead-uri" to options that have mapped
# vocabulary data
controlledVocabURIFor = (option) ->
  group = option.closest(".form-fields-wrapper").attr("data-group")
  type = option.val()
  return controlledVocabMap[group]?[type]

# Checks the given input/select combination to see if the input needs a typeahead attached
checkControlledVocabulary = (input, select) ->
  input.typeahead("destroy")
  option = select.find("option").filter(":selected")
  uri = controlledVocabURIFor(option)
  if uri
    input.typeahead([{
      name: option.val()
      remote: {
        url: uri
        wildcard: "VOCABQUERY"
      }
      valueKey: "label"
      limit: 10
    }])

    # Handle selections so we can populate hidden fields
    input.on 'typeahead:selected', (object, datum) ->
      hiddenField = input.closest(".form-fields-wrapper").find("input.internal-field")
      hiddenField.attr("value", datum.id)
