def _model_to_dict(model):
    try:
        return model.model_dump()
    except AttributeError:
        return model.dict()
